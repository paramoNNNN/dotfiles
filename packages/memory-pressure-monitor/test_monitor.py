import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("memory_monitor", Path(__file__).with_name("monitor.py"))
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)


def healthy():
    return {"platform": "Linux", "total_bytes": 1000, "available_bytes": 500,
            "swap_used_bytes": 0, "top": [],
            "psi": monitor.parse_psi("some avg10=0.00 total=10\nfull avg10=0.00 total=10")}


class MemoryTests(unittest.TestCase):
    def test_low_available_and_pressure_are_independent_triggers(self):
        record = healthy()
        self.assertEqual(monitor.severity(record), "normal")
        record["available_bytes"] = 100
        self.assertEqual(monitor.severity(record), "warning")
        record["available_bytes"] = 50
        self.assertEqual(monitor.severity(record), "critical")
        record["available_bytes"] = 500
        record["psi"]["some"]["avg10"] = 10
        self.assertEqual(monitor.severity(record), "warning")
        record["psi"]["full"]["avg10"] = 10
        self.assertEqual(monitor.severity(record), "critical")

    def test_short_pressure_spike_is_not_lost_in_avg10(self):
        previous = healthy() | {"boot_id": "boot", "epoch": 100}
        current = healthy()
        current["psi"]["full"]["total"] = 1000010
        with patch.object(monitor, "linux_sample", return_value=current), \
             patch.object(monitor, "boot_id", return_value="boot"), \
             patch.object(monitor.time, "time", return_value=105):
            result = monitor.sample(previous)
        self.assertEqual(result["interval_psi"]["full"], 20)
        self.assertEqual(result["severity"], "critical")

    def test_rotation_and_previous_boot_ignore_torn_record(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            previous = healthy() | {"boot_id": "old", "epoch": 100,
                                    "timestamp": "old-boot", "used_percent": 50, "severity": "normal"}
            current = previous | {"boot_id": "current", "timestamp": "current-boot"}
            with patch.object(monitor, "STATE", state), patch.object(monitor, "LOG_LIMIT", 1):
                monitor.save(previous)
                monitor.save(current)
                self.assertTrue((state / "samples.jsonl.1").exists())
                with (state / "samples.jsonl").open("a") as output:
                    output.write('{"incomplete"')
                output = io.StringIO()
                with patch.object(monitor, "boot_id", return_value="current"), contextlib.redirect_stdout(output):
                    monitor.report(True)
                self.assertIn("old-boot", output.getvalue())
                self.assertNotIn("current-boot", output.getvalue())
                self.assertEqual(json.loads((state / "status.json").read_text())["boot_id"], "current")

    def test_status_does_not_show_stale_or_previous_boot_as_healthy(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            with patch.object(monitor, "STATE", state), patch.object(monitor, "boot_id", return_value="new"), \
                 patch.object(monitor.time, "time", return_value=100):
                self.assertEqual(monitor.status()["severity"], "unknown")
                for record in ({"epoch": 99, "boot_id": "old", "severity": "normal"},
                               {"epoch": 70, "boot_id": "new", "severity": "normal"}):
                    (state / "status.json").write_text(json.dumps(record))
                    self.assertEqual(monitor.status()["severity"], "unknown")


if __name__ == "__main__":
    unittest.main()
