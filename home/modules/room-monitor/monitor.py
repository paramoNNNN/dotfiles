"""Opt-in, local webcam snapshots with a fixed armed reference and Telegram alerts."""

import argparse
import getpass
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import time
import urllib.request
import uuid
from datetime import datetime, timezone

from PIL import Image, ImageFilter


STATE = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "room-monitor"
PHOTOS = STATE / "photos"
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "room-monitor/config.json"
REFERENCE = STATE / "reference.jpg"
DEFAULTS = {
    "device": "/dev/video0",
    "video_size": "640x480",
    "input_format": None,
    "framerate": None,
    "interval_seconds": 300,
    "arming_delay_seconds": 30,
    "confirm_delay_seconds": 10,
    "pixel_threshold": 25,
    "changed_fraction": 0.02,
    "alert_cooldown_seconds": 1800,
}


def settings():
    cfg = DEFAULTS | (json.loads(CONFIG.read_text()) if CONFIG.exists() else {})
    for key in ("interval_seconds", "confirm_delay_seconds", "alert_cooldown_seconds"):
        if not isinstance(cfg[key], (int, float)) or cfg[key] <= 0:
            raise ValueError(f"{key} must be positive")
    if not 0 < cfg["changed_fraction"] <= 1 or not 0 < cfg["pixel_threshold"] < 255:
        raise ValueError("Invalid change thresholds")
    if cfg["arming_delay_seconds"] < 0:
        raise ValueError("arming_delay_seconds must not be negative")
    return cfg


def prepare():
    os.umask(0o077)
    PHOTOS.mkdir(parents=True, exist_ok=True)
    STATE.chmod(0o700)
    PHOTOS.chmod(0o700)


def cleanup(now=None):
    cutoff = (time.time() if now is None else now) - 86400
    for path in PHOTOS.glob("*.jpg"):
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


def run(cfg):
    REFERENCE.unlink(missing_ok=True)
    alert(cfg, f"Room monitor arming in {cfg['arming_delay_seconds']} seconds. Leave the camera fixed.")
    time.sleep(cfg["arming_delay_seconds"])
    try:
        first = capture(cfg)
        REFERENCE.write_bytes(first.read_bytes())
        alert(cfg, f"Room monitor armed. Checking every {cfg['interval_seconds']} seconds.", first)
        last_alert = float("-inf")
        while True:
            time.sleep(cfg["interval_seconds"])
            current = capture(cfg)
            fraction = change_fraction(REFERENCE, current, cfg["pixel_threshold"])
            print(f"{current.name}: {fraction:.1%} changed", flush=True)
            if fraction < cfg["changed_fraction"]:
                continue
            if time.monotonic() - last_alert < cfg["alert_cooldown_seconds"]:
                continue
            time.sleep(cfg["confirm_delay_seconds"])
            confirmation = capture(cfg)
            fraction = change_fraction(REFERENCE, confirmation, cfg["pixel_threshold"])
            if fraction >= cfg["changed_fraction"]:
                delivered = alert(cfg, f"Room change detected: {fraction:.1%} of the view differs from the armed reference.", confirmation)
                # Retry on the next check if Telegram is configured but unavailable.
                if delivered or not cfg.get("telegram_bot_token"):
                    last_alert = time.monotonic()
    except Exception as error:
        print(str(error), file=sys.stderr, flush=True)
        alert(cfg, f"Room monitor stopped: {type(error).__name__}. Check camera access and the journal.")
        raise SystemExit(1) from None
    finally:
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
    parser.add_argument("command", choices=["arm", "disarm", "toggle", "status", "photos", "setup-telegram", "test-alert", "capture", "cleanup", "clear-reference", "run"])
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
    elif command == "photos":
        subprocess.run(["xdg-open", str(PHOTOS)], check=True)
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
        run(settings())


if __name__ == "__main__":
    main()
