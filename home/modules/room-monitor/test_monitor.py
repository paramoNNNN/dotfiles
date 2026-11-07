"""Offline checks for change detection, retention, and Telegram requests."""

import importlib.util
import io
import os
import subprocess
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw


spec = importlib.util.spec_from_file_location("monitor", Path(__file__).with_name("monitor.py"))
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)


class MonitorTests(unittest.TestCase):
    def test_capture_failure_exposes_camera_diagnostic_and_cleans_partial_photo(self):
        with tempfile.TemporaryDirectory() as directory:
            def failed_capture(command, **kwargs):
                Path(command[-1]).write_bytes(b"partial")
                self.assertEqual(command[command.index("-input_format") + 1], "yuyv422")
                self.assertEqual(command[command.index("-framerate") + 1], "15")
                raise subprocess.CalledProcessError(251, command, stderr=b"Device or resource busy")

            cfg = monitor.DEFAULTS | {"input_format": "yuyv422", "framerate": 15}
            with patch.object(monitor, "PHOTOS", Path(directory)), patch.object(monitor.subprocess, "run", side_effect=failed_capture):
                with self.assertRaisesRegex(RuntimeError, "Device or resource busy"):
                    monitor.capture(cfg)
            self.assertEqual(list(Path(directory).iterdir()), [])

    def test_change_and_global_brightness(self):
        with tempfile.TemporaryDirectory() as directory:
            reference, current = Path(directory) / "reference.png", Path(directory) / "current.png"
            image = Image.new("L", (640, 480), 80)
            image.save(reference)
            image.save(current)
            self.assertEqual(monitor.change_fraction(reference, current), 0)
            Image.new("L", image.size, 110).save(current)
            self.assertEqual(monitor.change_fraction(reference, current), 0)
            # A moved object against the room background should trigger the default threshold.
            ImageDraw.Draw(image).rectangle((100, 100, 220, 220), fill=200)
            image.save(current)
            self.assertGreater(monitor.change_fraction(reference, current), 0.02)

    def test_retention_keeps_recent_photos_and_other_files(self):
        with tempfile.TemporaryDirectory() as directory:
            photos = Path(directory)
            now = 200000
            for name, age in (("old.jpg", 86401), ("recent.jpg", 86399), ("notes.txt", 90000)):
                file = photos / name
                file.write_text("test")
                os.utime(file, (now - age, now - age))
            with patch.object(monitor, "PHOTOS", photos):
                monitor.cleanup(now)
            self.assertFalse((photos / "old.jpg").exists())
            self.assertTrue((photos / "recent.jpg").exists())
            self.assertTrue((photos / "notes.txt").exists())

    def test_photo_alert_and_secret_safe_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            photo = Path(directory) / "photo.jpg"
            Image.new("RGB", (10, 10)).save(photo)
            cfg = {"telegram_bot_token": "SECRET", "telegram_chat_id": "123"}
            with patch.object(monitor.urllib.request, "urlopen") as request:
                request.return_value.__enter__.return_value = io.BytesIO(b'{"ok":true}')
                self.assertTrue(monitor.telegram(cfg, "Room changed", photo))
                sent = request.call_args.args[0]
                self.assertIn(b"Room changed", sent.data)
                self.assertIn(photo.read_bytes(), sent.data)
            output = io.StringIO()
            with patch.object(monitor.urllib.request, "urlopen", side_effect=OSError("SECRET")), patch.object(monitor, "desktop"), patch("sys.stdout", output):
                self.assertFalse(monitor.telegram(cfg, "test"))
            self.assertNotIn("SECRET", output.getvalue())


if __name__ == "__main__":
    unittest.main()
