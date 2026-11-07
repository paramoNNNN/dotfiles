"""Offline regression checks for the scheduled vault helpers."""

import contextlib
from datetime import datetime, timedelta
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import urllib.error
from zoneinfo import ZoneInfo

HERE = Path(__file__).parent
spec = importlib.util.spec_from_file_location(
    "calendar_helper", HERE / "prepare-calendar-meetings.py"
)
calendar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(calendar)


class CalendarTests(unittest.TestCase):
    def test_create_only_notes_and_audit_window(self):
        today = datetime.now(ZoneInfo("Asia/Tehran")).date()
        future = today + timedelta(days=1)
        content = (
            "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\n"
            f"DTSTART;VALUE=DATE:{today:%Y%m%d}\r\n"
            "SUMMARY:Review project\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\n"
            f"DTSTART;VALUE=DATE:{future:%Y%m%d}\r\n"
            "SUMMARY:Future meeting\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\n"
            f"DTSTART;VALUE=DATE:{today:%Y%m%d}\r\n"
            "SUMMARY:Daily planning\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
        ).encode()
        with tempfile.TemporaryDirectory() as directory:
            vault = Path(directory)
            (vault / "Templates").mkdir()
            (vault / "Templates/Meeting.md").write_text(
                "---\ndate: {{date:YYYY-MM-DD}}\n---\n# {{title}}\n"
                "## Raw notes\n\n## Summary\n\n## Decisions\n\n## Actions\n"
            )
            env = {
                "OBSIDIAN_VAULT_ROOT": directory,
                "WORK_CALENDAR_ICS_URL": "https://calendar.example/private-token",
            }
            with patch.dict(os.environ, env), patch.object(
                calendar.urllib.request, "urlopen", side_effect=lambda *a, **k: io.BytesIO(content)
            ):
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    calendar.main()
                result = json.loads(output.getvalue())
                self.assertEqual(len(result["meetings"]), 1)
                target = vault / f"Meetings/{today}-review-project.md"
                self.assertIn('start: "00:00"', target.read_text())
                self.assertTrue((vault / f"Meetings/{future}-future-meeting.md").exists())
                self.assertFalse((vault / f"Meetings/{today}-daily-planning.md").exists())
                target.write_text("Human-written notes must survive.\n")
                with contextlib.redirect_stdout(io.StringIO()):
                    calendar.main()
                self.assertEqual(target.read_text(), "Human-written notes must survive.\n")

    def test_calendar_outage_does_not_leak_private_url(self):
        with patch.dict(os.environ, {"WORK_CALENDAR_ICS_URL": "https://private/token"}), patch.object(
            calendar.urllib.request, "urlopen", side_effect=urllib.error.URLError("https://private/token")
        ):
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                calendar.main()
            result = json.loads(output.getvalue())
            self.assertFalse(result["calendarAvailable"])
            self.assertNotIn("private/token", output.getvalue())


@unittest.skipUnless(os.environ.get("ARCHIVE_HELPER"), "Set ARCHIVE_HELPER to the built executable")
class ArchiveTests(unittest.TestCase):
    def test_previous_week_only_and_collision_preservation(self):
        today = datetime.now(ZoneInfo("Asia/Tehran")).date()
        week_start = today - timedelta(days=(today.weekday() + 2) % 7)
        last_week = week_start - timedelta(days=7)
        old = last_week - timedelta(days=1)
        with tempfile.TemporaryDirectory() as directory:
            vault = Path(directory)
            for name in ["Daily", "Briefings", "Archive"]:
                (vault / name).mkdir()
            name = f"{last_week}.md"
            (vault / "Daily" / name).write_text("- [ ] Carry this task\n")
            (vault / "Daily" / f"{today}.md").write_text("Current\n")
            (vault / "Daily" / f"{old}.md").write_text("Outside previous week\n")
            archived = vault / "Archive" / str(last_week)[:7] / "Daily"
            archived.mkdir(parents=True)
            earlier = "Earlier version\n"
            (archived / name).write_text(earlier)
            env = {**os.environ, "OBSIDIAN_VAULT_ROOT": directory}
            command = [os.environ["ARCHIVE_HELPER"]]
            result = json.loads(subprocess.check_output(command, env=env, text=True))
            self.assertEqual(result["archivedDaily"], 1)
            self.assertEqual((archived / name).read_text(), "- [ ] Carry this task\n")
            digest = hashlib.sha256(earlier.encode()).hexdigest()
            conflict = vault / "Archive" / str(last_week)[:7] / "Conflicts" / digest / "Daily" / name
            self.assertEqual(conflict.read_text(), earlier)
            self.assertTrue((vault / "Daily" / f"{today}.md").exists())
            self.assertTrue((vault / "Daily" / f"{old}.md").exists())
            rerun = json.loads(subprocess.check_output(command, env=env, text=True))
            self.assertEqual(rerun["archivedDaily"], 0)
            self.assertEqual(len(rerun["remainingTodos"]), 1)


if __name__ == "__main__":
    unittest.main()
