"""Offline tests: no screen, camera, SSH connection or desktop session is used."""
import importlib.util
from datetime import datetime, timezone
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

from PIL import Image

spec = importlib.util.spec_from_file_location("capture", Path(__file__).with_name("capture.py"))
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


class CaptureTests(unittest.TestCase):
    def test_mac_lock_idle_console_and_permission_gates(self):
        session = capture.MacSession.__new__(capture.MacSession)
        session.idle_seconds = 300
        quartz = Mock()
        quartz.kCGSessionOnConsoleKey = "console"
        session.quartz = quartz
        quartz.CGSessionCopyCurrentDictionary.return_value = {"console": True}
        quartz.CGEventSourceSecondsSinceLastEventType.return_value = 20
        quartz.CGPreflightScreenCaptureAccess.return_value = True
        self.assertTrue(capture.allowed(session))
        for dictionary in (None, {}, {"console": False},
                           {"console": True, "CGSSessionScreenIsLocked": True}):
            quartz.CGSessionCopyCurrentDictionary.return_value = dictionary
            self.assertFalse(capture.allowed(session))
        quartz.CGSessionCopyCurrentDictionary.return_value = {"console": True}
        quartz.CGEventSourceSecondsSinceLastEventType.return_value = 300
        self.assertFalse(capture.allowed(session))
        quartz.CGEventSourceSecondsSinceLastEventType.return_value = 20
        quartz.CGPreflightScreenCaptureAccess.return_value = False
        self.assertFalse(capture.allowed(session))

    def test_lock_idle_unknown_and_dead_watcher_fail_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            watcher = Mock()
            watcher.poll.return_value = None
            with patch.object(capture, "RUNTIME", runtime), patch.object(capture, "console_active", return_value=True), \
                 patch.object(capture.subprocess, "run") as run:
                self.assertFalse(capture.allowed(watcher))
                (runtime / "idle").write_text("active")
                for response, expected in [('false', True), ('{"locked":false}', True),
                                           ('true', False), ('{}', False), ('null', False),
                                           ('0', False), ('invalid', False)]:
                    run.return_value.stdout = response
                    self.assertEqual(capture.allowed(watcher), expected, response)
                run.side_effect = subprocess.TimeoutExpired("hyprctl", 2)
                self.assertFalse(capture.allowed(watcher))
                (runtime / "idle").write_text("idle")
                self.assertFalse(capture.allowed(watcher))
                watcher.poll.return_value = 1
                self.assertFalse(capture.allowed(watcher))

    def test_inactive_remote_or_unknown_console_is_rejected(self):
        for properties, expected in [("Active=yes\nRemote=no\nLockedHint=no", True),
                                     ("Active=no\nRemote=no\nLockedHint=no", False),
                                     ("Active=yes\nRemote=yes\nLockedHint=no", False),
                                     ("Active=yes\nRemote=no\nLockedHint=yes", False), ("", False)]:
            with patch.object(capture.subprocess, "run", side_effect=[
                Mock(stdout="c1\n"), Mock(stdout=properties),
            ]):
                self.assertEqual(capture.console_active(), expected)

    def test_lock_during_camera_aborts_process(self):
        process = Mock()
        process.poll.return_value = None
        with patch.object(capture, "allowed", side_effect=[True, False]), \
             patch.object(capture.subprocess, "Popen", return_value=process):
            with self.assertRaises(capture.SessionInactive):
                capture.guarded(["ffmpeg"], Mock(), 30)
        process.terminate.assert_called_once()
        process.wait.assert_called_once()

    def test_capture_failures_do_not_discard_other_successful_images(self):
        cases = [
            ({}, {"screen", "webcam"}),
            ({"ffmpeg": RuntimeError("camera busy")}, {"screen"}),
            ({"ffmpeg": OSError("camera missing")}, {"screen"}),
            ({"ffmpeg": RuntimeError("camera timed out")}, {"screen"}),
            ({"ffmpeg": capture.SessionInactive()}, {"screen"}),
            ({"grim": RuntimeError("screenshot failed")}, {"webcam"}),
            ({"grim": capture.SessionInactive()}, set()),
            ({"grim": RuntimeError("screen unavailable"), "ffmpeg": OSError("camera missing")}, set()),
        ]
        for failures, expected in cases:
            with self.subTest(failures=failures), tempfile.TemporaryDirectory() as directory:
                state = Path(directory)
                queue = state / "queue"
                queue.mkdir()

                def fake_capture(command, watcher, timeout):
                    if command[0] in failures:
                        # A failed camera may have already written an incomplete image.
                        Path(command[-1]).write_bytes(b"partial")
                        raise failures[command[0]]
                    color = "blue" if command[0] == "ffmpeg" else "red"
                    Image.new("RGB", (640, 480), color).save(command[-1])

                with patch.object(capture, "STATE", state), patch.object(capture, "QUEUE", queue), \
                     patch.object(capture, "allowed", return_value=True), \
                     patch.object(capture, "guarded", side_effect=fake_capture), \
                     patch.object(capture, "datetime", wraps=datetime) as clock:
                    clock.now.return_value = datetime(2026, 11, 4, 21, 0, tzinfo=timezone.utc).astimezone(capture.CAPTURE_TIMEZONE)
                    cfg = {"max_queue_bytes": 100000, "device": "/dev/video0", "video_size": "640x480"}
                    capture.capture_cycle(cfg, Mock())
                photos = list(queue.rglob("*.jpg"))
                self.assertEqual(len(photos), 1 if expected else 0)
                self.assertEqual(list(state.glob("pending-*")), [])
                if photos:
                    self.assertEqual(len(photos[0].relative_to(queue).parts), 2)
                    self.assertEqual(photos[0].parent.name, "2026-11-05")
                    self.assertTrue(photos[0].name.startswith("2026-11-05T00-30-00."))
                    self.assertTrue(photos[0].name.endswith("+0330.jpg"))
                    with Image.open(photos[0]) as image:
                        red, _, blue = image.getpixel((10, 10))
                        self.assertGreater(red if "screen" in expected else blue, 240)
                        if len(expected) == 2:
                            self.assertGreater(image.getpixel((600, 440))[2], 240)

    def test_composite_preserves_screen_size_and_embeds_capture_date(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            screen, webcam, target = (root / name for name in ("screen.jpg", "webcam.jpg", "combined.jpg"))
            Image.new("RGB", (640, 480), "red").save(screen)
            Image.new("RGB", (160, 120), "blue").save(webcam)
            captured_at = datetime(2026, 11, 4, 21, 0, tzinfo=timezone.utc).astimezone(capture.CAPTURE_TIMEZONE)
            capture.compose_capture({"screen": screen, "webcam": webcam}, target, captured_at)
            with Image.open(target) as image:
                self.assertEqual(image.size, (640, 480))
                self.assertGreater(image.getpixel((10, 10))[0], 240)
                self.assertGreater(image.getpixel((600, 440))[2], 240)
                self.assertEqual(image.getexif()[36867], "2026:11:05 00:30:00")
                self.assertEqual(image.getexif()[36881], "+03:30")

    def test_full_queue_pauses_capture(self):
        with patch.object(capture, "allowed", return_value=True), \
             patch.object(capture, "queue_size", return_value=100), \
             patch.object(capture, "guarded") as guarded:
            capture.capture_cycle({"max_queue_bytes": 100}, Mock())
            guarded.assert_not_called()

    def test_upload_failure_keeps_queued_files(self):
        with tempfile.TemporaryDirectory() as directory:
            queue = Path(directory)
            pair = queue / "pair"
            pair.mkdir()
            (pair / "screen.jpg").write_bytes(b"photo")
            cfg = {"remote": "paranas@192.168.1.215", "remote_path": "/storage/activity-captures/taha-pc",
                   "identity_file": "~/.ssh/activity_capture_ed25519"}
            with patch.object(capture, "QUEUE", queue), \
                 patch.object(capture.subprocess, "run", side_effect=subprocess.TimeoutExpired("rsync", 180)) as run:
                capture.upload(cfg)
                command = run.call_args.args[0]
                self.assertIn("--remove-source-files", command)
                self.assertIn("StrictHostKeyChecking=yes", command[command.index("-e") + 1])
            self.assertTrue((pair / "screen.jpg").exists())


if __name__ == "__main__":
    unittest.main()
