"""Offline checks for change detection, retention, and Telegram requests."""

import importlib.util
import io
import json
import os
import shutil
import subprocess
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import Mock, patch

from PIL import Image, ImageDraw


spec = importlib.util.spec_from_file_location("monitor", Path(__file__).with_name("monitor.py"))
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)


class MonitorTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("ffmpeg") and shutil.which("ffprobe"), "FFmpeg integration tools unavailable")
    def test_recording_writes_photos_and_playable_video_with_audio(self):
        # Exercise the real output pipeline without accessing a camera or microphone.
        popen = subprocess.Popen

        def synthetic_inputs(command, **kwargs):
            outputs = command[command.index("-map"):]
            return popen(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
                          "-re", "-f", "lavfi", "-i", "testsrc=size=160x120:rate=10",
                          "-re", "-f", "lavfi", "-i", "sine=frequency=440", *outputs], **kwargs)

        with tempfile.TemporaryDirectory() as directory:
            photos, videos = Path(directory) / "photos", Path(directory) / "videos"
            photos.mkdir()
            videos.mkdir()
            with patch.object(monitor, "PHOTOS", photos), patch.object(monitor, "VIDEOS", videos), \
                 patch.object(monitor.subprocess, "Popen", side_effect=synthetic_inputs):
                recording = monitor.Recording(monitor.DEFAULTS | {"active_interval_seconds": 0.2})
                try:
                    deadline = time.monotonic() + 10
                    while len(list(photos.glob("*.jpg"))) < 3:
                        recording.latest()
                        if time.monotonic() >= deadline:
                            self.fail("FFmpeg did not produce periodic photos")
                        time.sleep(0.05)
                    with Image.open(recording.latest()) as image:
                        image.verify()
                finally:
                    recording.stop()
            video = next(videos.glob("*.mp4"))
            result = subprocess.run(["ffprobe", "-v", "error", "-show_streams", "-of", "json", str(video)],
                                    capture_output=True, check=True, timeout=10)
            streams = json.loads(result.stdout)["streams"]
            self.assertEqual({stream["codec_type"] for stream in streams}, {"video", "audio"})

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
            for name, age in (("old.jpg", 86401), ("recent.jpg", 86399), ("old.mp4", 86401), ("recent.mp4", 86399), ("notes.txt", 90000)):
                file = photos / name
                file.write_text("test")
                os.utime(file, (now - age, now - age))
            with patch.object(monitor, "PHOTOS", photos), patch.object(monitor, "VIDEOS", photos):
                monitor.cleanup(now)
            self.assertFalse((photos / "old.jpg").exists())
            self.assertTrue((photos / "recent.jpg").exists())
            self.assertTrue((photos / "notes.txt").exists())
            self.assertFalse((photos / "old.mp4").exists())
            self.assertTrue((photos / "recent.mp4").exists())

    def test_event_records_and_keeps_fast_captures_during_alert_cooldown(self):
        now = 0
        sleeps = []

        def sleep(seconds):
            nonlocal now
            sleeps.append(seconds)
            now += seconds
            if now > 330:
                raise KeyboardInterrupt

        recording = Mock()
        recording.latest.side_effect = [Path(f"active-{index}.jpg") for index in range(10)]
        cfg = monitor.DEFAULTS | {"arming_delay_seconds": 0, "active_hold_seconds": 10}
        with tempfile.TemporaryDirectory() as directory:
            photo = Path(directory) / "first.jpg"
            photo.write_bytes(b"reference")
            reference = Path(directory) / "reference.jpg"
            with patch.object(monitor, "REFERENCE", reference), \
                 patch.object(monitor, "capture", return_value=photo) as capture, \
                 patch.object(monitor, "Recording", return_value=recording) as start, \
                 patch.object(monitor, "change_fraction", side_effect=[0.1, 0.1, 0.1, 0.1, 0, 0]), \
                 patch.object(monitor, "alert", return_value=True) as alert, \
                 patch.object(monitor, "cleanup"), \
                 patch.object(monitor.time, "sleep", side_effect=sleep), \
                 patch.object(monitor.time, "monotonic", side_effect=lambda: now):
                with self.assertRaises(KeyboardInterrupt):
                    monitor.run(cfg)
            self.assertFalse(reference.exists())
        self.assertEqual(sleeps, [0, 300, 5, 5, 5, 5, 5, 300])
        self.assertEqual(capture.call_count, 2)  # Never reopen the recording's camera.
        start.assert_called_once_with(cfg)
        recording.stop.assert_called_once()
        self.assertEqual(alert.call_count, 3)  # Arming, armed, one confirmed change.

    def test_disarming_stops_recording_and_removes_reference(self):
        recording = Mock()
        cfg = monitor.DEFAULTS | {"arming_delay_seconds": 0}
        with tempfile.TemporaryDirectory() as directory:
            photo = Path(directory) / "first.jpg"
            photo.write_bytes(b"reference")
            reference = Path(directory) / "reference.jpg"
            with patch.object(monitor, "REFERENCE", reference), \
                 patch.object(monitor, "capture", return_value=photo), \
                 patch.object(monitor, "Recording", return_value=recording), \
                 patch.object(monitor, "change_fraction", return_value=0.1), \
                 patch.object(monitor, "alert"), patch.object(monitor, "cleanup"), \
                 patch.object(monitor.time, "sleep", side_effect=[None, None, SystemExit(0)]):
                with self.assertRaises(SystemExit):
                    monitor.run(cfg)
            recording.stop.assert_called_once()
            self.assertFalse(reference.exists())

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
