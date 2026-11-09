"""Manually armed room monitor with local photos, audio/video, and Telegram alerts."""

import argparse
import getpass
import json
import os
from pathlib import Path
import signal
import statistics
import subprocess
import sys
import tempfile
import time
import urllib.request
import uuid
from datetime import datetime, timezone

from PIL import Image, ImageFilter


STATE = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "room-monitor"
PHOTOS = STATE / "photos"
VIDEOS = STATE / "videos"
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "room-monitor/config.json"
REFERENCE = STATE / "reference.jpg"
DEFAULTS = {
    "device": "/dev/video0",
    "video_size": "640x480",
    "input_format": None,
    "framerate": None,
    "interval_seconds": 300,
    "active_interval_seconds": 5,
    "active_hold_seconds": 120,
    "record_video": True,
    "audio_device": "default",
    "arming_delay_seconds": 30,
    "confirm_delay_seconds": 10,
    "pixel_threshold": 25,
    "changed_fraction": 0.02,
    "alert_cooldown_seconds": 1800,
}


def settings():
    cfg = DEFAULTS | (json.loads(CONFIG.read_text()) if CONFIG.exists() else {})
    for key in ("interval_seconds", "active_interval_seconds", "active_hold_seconds", "confirm_delay_seconds", "alert_cooldown_seconds"):
        if not isinstance(cfg[key], (int, float)) or cfg[key] <= 0:
            raise ValueError(f"{key} must be positive")
    if not 0 < cfg["changed_fraction"] <= 1 or not 0 < cfg["pixel_threshold"] < 255:
        raise ValueError("Invalid change thresholds")
    if cfg["arming_delay_seconds"] < 0:
        raise ValueError("arming_delay_seconds must not be negative")
    if not isinstance(cfg["record_video"], bool):
        raise ValueError("record_video must be true or false")
    if not isinstance(cfg["audio_device"], str) or not cfg["audio_device"].strip():
        raise ValueError("audio_device must name a PulseAudio/PipeWire source")
    return cfg


def prepare():
    os.umask(0o077)
    PHOTOS.mkdir(parents=True, exist_ok=True)
    VIDEOS.mkdir(parents=True, exist_ok=True)
    STATE.chmod(0o700)
    PHOTOS.chmod(0o700)
    VIDEOS.chmod(0o700)


def cleanup(now=None):
    cutoff = (time.time() if now is None else now) - 86400
    for path in (*PHOTOS.glob("*.jpg"), *VIDEOS.glob("*.mp4")):
        try:
            if path.stat().st_mtime < cutoff:
                path.unlink()
        except FileNotFoundError:
            pass  # The timer and capture loop may prune concurrently.


def desktop(message, photo=None):
    args = ["notify-send", "--app-name=Room Monitor", "Room Monitor", message]
    if photo:
        args[1:1] = ["--icon", str(photo)]
    try:
        subprocess.run(args, timeout=5, check=False, capture_output=True)
    except (OSError, subprocess.TimeoutExpired):
        pass


def telegram(cfg, message, photo=None):
    token, chat = cfg.get("telegram_bot_token"), cfg.get("telegram_chat_id")
    if not token or not chat:
        return False
    if photo:
        boundary = uuid.uuid4().hex
        body = b""
        for key, value in (("chat_id", chat), ("caption", message)):
            body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{key}\"\r\n\r\n{value}\r\n").encode()
        body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"photo\"; filename=\"room.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n").encode()
        body += photo.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
        content_type = f"multipart/form-data; boundary={boundary}"
        method = "sendPhoto"
    else:
        body = json.dumps({"chat_id": chat, "text": message}).encode()
        content_type = "application/json"
        method = "sendMessage"
    request = urllib.request.Request(
        f"https://api.telegram.org/bot{token}/{method}", data=body,
        headers={"Content-Type": content_type},
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            if not json.load(response).get("ok"):
                raise ValueError("Telegram rejected message")
        return True
    except Exception:
        # URL exceptions can contain the bot token; never print them.
        print("Telegram delivery failed; check credentials and connectivity.", flush=True)
        desktop("Telegram delivery failed. Check the room-monitor journal.")
        return False


def alert(cfg, message, photo=None):
    print(message, flush=True)
    desktop(message, photo)
    return telegram(cfg, message, photo)


def capture(cfg):
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    target = PHOTOS / f"{stamp}.jpg"
    temporary = target.with_suffix(".tmp.jpg")
    command = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
               "-f", "v4l2", "-video_size", cfg["video_size"]]
    if cfg.get("input_format"):
        command += ["-input_format", cfg["input_format"]]
    if cfg.get("framerate"):
        command += ["-framerate", str(cfg["framerate"])]
    command += ["-i", cfg["device"], "-vf", "select=gte(n\\,30)",
                "-frames:v", "1", "-q:v", "3", "-update", "1", "-y", str(temporary)]
    try:
        # Discard the first 30 frames to allow camera exposure to settle.
        try:
            subprocess.run(command, check=True, timeout=30, capture_output=True)
        except subprocess.CalledProcessError as error:
            detail = (error.stderr or b"").decode(errors="replace").strip()
            raise RuntimeError(f"Capture failed for {cfg['device']}:\n{detail or 'FFmpeg returned no diagnostic'}") from None
        except subprocess.TimeoutExpired:
            raise RuntimeError(f"Camera {cfg['device']} did not deliver a photo within 30 seconds. Check whether it is a dummy camera or in use.") from None
        with Image.open(temporary) as image:
            image.verify()
        temporary.replace(target)
        cleanup()
        return target
    finally:
        temporary.unlink(missing_ok=True)


def pixels(path):
    with Image.open(path) as image:
        return image.convert("L").resize((160, 120)).filter(ImageFilter.GaussianBlur(1)).tobytes()


def change_fraction(reference, current, threshold=25):
    differences = [b - a for a, b in zip(pixels(reference), pixels(current))]
    # Compensate for a global brightness shift, without learning away moved objects.
    brightness = statistics.median(differences)
    return sum(abs(value - brightness) > threshold for value in differences) / len(differences)


class Recording:
    """One camera owner for audio/video and periodic, atomically written photos."""

    def __init__(self, cfg):
        self.prefix = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
        self.diagnostics = tempfile.TemporaryFile()
        command = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
                   "-f", "v4l2", "-video_size", cfg["video_size"]]
        if cfg.get("input_format"):
            command += ["-input_format", cfg["input_format"]]
        if cfg.get("framerate"):
            command += ["-framerate", str(cfg["framerate"])]
        command += ["-i", cfg["device"], "-thread_queue_size", "512",
                    "-f", "pulse", "-i", cfg["audio_device"],
                    "-map", "0:v:0", "-map", "1:a:0", "-c:v", "libx264",
                    "-preset", "ultrafast", "-crf", "25", "-pix_fmt", "yuv420p",
                    "-c:a", "aac", "-b:a", "96k", "-force_key_frames", "expr:gte(t,n_forced*60)",
                    "-f", "segment", "-segment_time", "60", "-reset_timestamps", "1",
                    str(VIDEOS / f"{self.prefix}-%04d.mp4"),
                    "-map", "0:v:0", "-vf", f"fps=1/{cfg['active_interval_seconds']}",
                    "-q:v", "3", "-f", "image2", "-atomic_writing", "1",
                    str(PHOTOS / f"{self.prefix}-active-%08d.jpg")]
        try:
            self.process = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=self.diagnostics)
        except BaseException:
            self.diagnostics.close()
            raise

    def latest(self):
        if self.process.poll() is not None:
            self.diagnostics.seek(0)
            detail = self.diagnostics.read().decode(errors="replace").strip()
            raise RuntimeError(f"Video/audio recording stopped. Check camera and audio_device: {detail}")
        return max(PHOTOS.glob(f"{self.prefix}-active-*.jpg"), default=None)

    def stop(self):
        try:
            if self.process.poll() is None:
                # SIGINT lets FFmpeg finalize the current MP4 segment.
                self.process.send_signal(signal.SIGINT)
                try:
                    self.process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    self.process.kill()
                    self.process.wait()
        finally:
            self.diagnostics.close()


def run(cfg):
    recording = None
    REFERENCE.unlink(missing_ok=True)
    alert(cfg, f"Room monitor arming in {cfg['arming_delay_seconds']} seconds. Leave the camera fixed.")
    time.sleep(cfg["arming_delay_seconds"])
    try:
        first = capture(cfg)
        REFERENCE.write_bytes(first.read_bytes())
        alert(cfg, f"Room monitor armed. Checking every {cfg['interval_seconds']} seconds.", first)
        last_alert = float("-inf")
        active_until = float("-inf")
        confirm_at = None
        previous = None
        delay = cfg["interval_seconds"]
        while True:
            time.sleep(delay)
            started = time.monotonic()
            current = recording.latest() if recording else capture(cfg)
            if current is None or current == previous:
                delay = cfg["active_interval_seconds"]
                continue
            previous = current
            fraction = change_fraction(REFERENCE, current, cfg["pixel_threshold"])
            print(f"{current.name}: {fraction:.1%} changed", flush=True)
            if fraction >= cfg["changed_fraction"]:
                active_until = started + cfg["active_hold_seconds"]
                if cfg["record_video"] and recording is None:
                    recording = Recording(cfg)
                    print("Recording video with microphone audio locally.", flush=True)
                if started - last_alert >= cfg["alert_cooldown_seconds"]:
                    if confirm_at is None:
                        confirm_at = started + cfg["confirm_delay_seconds"]
                    elif started >= confirm_at:
                        delivered = alert(cfg, f"Room change detected: {fraction:.1%} of the view differs from the armed reference.", current)
                        if delivered or not cfg.get("telegram_bot_token"):
                            last_alert = time.monotonic()
                        confirm_at = None
            else:
                confirm_at = None
            active = started < active_until
            if recording and not active:
                recording.stop()
                recording = None
            cleanup()
            interval = cfg["active_interval_seconds"] if active else cfg["interval_seconds"]
            delay = max(0, interval - (time.monotonic() - started))
    except Exception as error:
        print(str(error), file=sys.stderr, flush=True)
        alert(cfg, f"Room monitor stopped: {type(error).__name__}. Check camera/microphone access and the journal.")
        raise SystemExit(1) from None
    finally:
        if recording:
            recording.stop()
        REFERENCE.unlink(missing_ok=True)


def setup_telegram():
    cfg = settings()
    cfg["telegram_bot_token"] = getpass.getpass("Telegram bot token (hidden): ").strip()
    if not cfg["telegram_bot_token"]:
        raise SystemExit("A bot token is required")
    chat = input("Telegram chat ID (Enter to discover private chats): ").strip()
    if not chat:
        token = cfg["telegram_bot_token"]
        try:
            with urllib.request.urlopen(f"https://api.telegram.org/bot{token}/getUpdates", timeout=20) as response:
                updates = json.load(response)["result"]
        except Exception:
            raise SystemExit("Could not discover chats. Check the bot token and connectivity.") from None
        chats = {}
        for update in updates:
            candidate = update.get("message", {}).get("chat", {})
            if candidate.get("type") == "private":
                chats[str(candidate["id"])] = candidate.get("first_name", "Private chat")
        if not chats:
            raise SystemExit("Send /start to your bot in Telegram, then run setup again.")
        for chat_id, name in chats.items():
            print(f"{chat_id}: {name}")
        chat = input("Choose the chat ID to receive alerts: ").strip()
        if chat not in chats:
            raise SystemExit("Choose a chat ID from the list")
    cfg["telegram_chat_id"] = chat
    CONFIG.parent.mkdir(parents=True, exist_ok=True)
    temporary = CONFIG.with_suffix(".tmp")
    temporary.write_text(json.dumps(cfg, indent=2) + "\n")
    temporary.chmod(0o600)
    temporary.replace(CONFIG)
    print(f"Saved privately to {CONFIG}. Run 'room-monitor test-alert' to test delivery.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["arm", "disarm", "toggle", "status", "photos", "videos", "setup-telegram", "test-alert", "capture", "cleanup", "clear-reference", "run"])
    args = parser.parse_args()
    prepare()
    command = args.command
    if command == "toggle":
        active = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "room-monitor.service"]).returncode == 0
        command = "disarm" if active else "arm"
    if command in ("arm", "disarm", "status"):
        action = {"arm": "start", "disarm": "stop", "status": "status"}[command]
        result = subprocess.run(["systemctl", "--user", action, "room-monitor.service"])
        if command == "disarm" and result.returncode == 0:
            alert(settings(), "Room monitor disarmed.")
        sys.exit(result.returncode)
    elif command in ("photos", "videos"):
        subprocess.run(["xdg-open", str(PHOTOS if command == "photos" else VIDEOS)], check=True)
    elif command == "cleanup":
        cleanup()
    elif command == "clear-reference":
        REFERENCE.unlink(missing_ok=True)
    elif command == "setup-telegram":
        setup_telegram()
    elif command == "test-alert":
        cfg = settings()
        if not cfg.get("telegram_bot_token") or not cfg.get("telegram_chat_id"):
            parser.error("Run room-monitor setup-telegram first")
        sys.exit(0 if telegram(cfg, "Room monitor test alert.") else 1)
    elif command == "capture":
        try:
            print(capture(settings()))
        except (RuntimeError, OSError) as error:
            raise SystemExit(str(error)) from None
    elif command == "run":
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
        run(settings())


if __name__ == "__main__":
    main()
