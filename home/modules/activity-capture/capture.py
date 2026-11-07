"""Archive screen and webcam snapshots from active Hyprland/macOS sessions."""

import argparse
from datetime import datetime
import fcntl
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import signal
import subprocess
import tempfile
import time
from zoneinfo import ZoneInfo

from PIL import Image, ImageOps


CAPTURE_TIMEZONE = ZoneInfo("Asia/Tehran")
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "activity-capture"
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "activity-capture"
QUEUE = STATE / "queue"
RUNTIME = (STATE / "runtime" if platform.system() == "Darwin" else
           Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / "activity-capture")


class MacSession:
    def __init__(self, cfg):
        import Quartz
        self.quartz = Quartz
        self.idle_seconds = cfg["idle_seconds"]

    def poll(self):
        return None

    def allowed(self):
        try:
            q = self.quartz
            session = q.CGSessionCopyCurrentDictionary()
            if not session or not session.get(q.kCGSessionOnConsoleKey, False):
                return False
            # macOS omits the lock key in a clean unlocked console session.
            locked = session.get("CGSSessionScreenIsLocked", False)
            if locked != False:
                return False
            idle = q.CGEventSourceSecondsSinceLastEventType(q.kCGEventSourceStateHIDSystemState,
                                                          q.kCGAnyInputEventType)
            return 0 <= idle < self.idle_seconds and bool(q.CGPreflightScreenCaptureAccess())
        except (OSError, ValueError, AttributeError):
            return False


def settings():
    cfg = json.loads((CONFIG / "defaults.json").read_text())
    override = CONFIG / "config.json"
    if override.exists():
        cfg.update(json.loads(override.read_text()))
    for key in ("interval_seconds", "idle_seconds", "max_queue_bytes"):
        if not isinstance(cfg[key], int) or isinstance(cfg[key], bool) or cfg[key] <= 0:
            raise ValueError(f"{key} must be a positive integer")
    # Both values become rsync remote-shell arguments. Only permit simple destinations.
    if not re.fullmatch(r"[\w.-]+@[\w.-]+", cfg["remote"], flags=re.ASCII):
        raise ValueError("remote must be user@hostname (or user@IPv4)")
    if not re.fullmatch(r"/[\w./-]+", cfg["remote_path"], flags=re.ASCII):
        raise ValueError("remote_path must be an absolute path without spaces")
    return cfg


def log(message):
    print(message, flush=True)


def console_active():
    session = subprocess.run(
        ["loginctl", "show-user", str(os.getuid()), "-p", "Display", "--value"],
        capture_output=True, text=True, check=True, timeout=2,
    ).stdout.strip()
    if not session:
        return False
    result = subprocess.run(
        ["loginctl", "show-session", session, "-p", "Active", "-p", "Remote", "-p", "LockedHint"],
        capture_output=True, text=True, check=True, timeout=2,
    )
    properties = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    return properties.get("Active") == "yes" and properties.get("Remote") == "no" and properties.get("LockedHint") == "no"


def allowed(watcher):
    """Unknown lock/idle/compositor state always skips capture."""
    if isinstance(watcher, MacSession):
        return watcher.allowed()
    if watcher.poll() is not None:
        return False
    try:
        if (RUNTIME / "idle").read_text() != "active":
            return False
        if not console_active():
            return False
        result = subprocess.run(
            ["hyprctl", "-j", "locked"], capture_output=True, text=True,
            check=True, timeout=2,
        )
        locked = json.loads(result.stdout)
        # Hyprland versions have used a JSON boolean and an object with 'locked'.
        if isinstance(locked, dict):
            locked = locked.get("locked")
        return locked is False
    except (OSError, ValueError, subprocess.SubprocessError):
        return False


class SessionInactive(Exception):
    pass


def guarded(command, watcher, timeout):
    """Abort an in-progress capture if the session becomes locked or idle."""
    if not allowed(watcher):
        raise SessionInactive()
    # Camera diagnostics can be long: a file avoids blocking on a full stderr pipe.
    with tempfile.TemporaryFile() as errors:
        process = subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=errors)
        deadline = time.monotonic() + timeout
        try:
            while True:
                if not allowed(watcher):
                    raise SessionInactive()
                if process.poll() is not None:
                    break
                if time.monotonic() >= deadline:
                    raise RuntimeError(f"{command[0]} capture timed out")
                time.sleep(0.5)
            if process.returncode:
                errors.seek(0)
                detail = errors.read(4096).decode(errors="replace").strip()
                raise RuntimeError(f"{command[0]} capture failed: {detail}")
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


def queue_size():
    return sum(path.stat().st_size for path in QUEUE.rglob("*") if path.is_file())


def compose_capture(images, target, captured_at):
    """One JPEG per interval, with a webcam inset when both sources succeeded."""
    primary = images.get("screen", images.get("webcam"))
    with Image.open(primary) as source:
        combined = ImageOps.exif_transpose(source).convert("RGB")
    if "screen" in images and "webcam" in images:
        with Image.open(images["webcam"]) as source:
            inset = ImageOps.exif_transpose(source).convert("RGB")
        margin = max(1, min(16, min(combined.size) // 40))
        border = max(1, min(3, min(combined.size) // 100))
        inset.thumbnail((max(1, combined.width // 4), max(1, combined.height // 3)))
        inset = ImageOps.expand(inset, border=border, fill="white")
        combined.paste(inset, (max(0, combined.width - inset.width - margin),
                              max(0, combined.height - inset.height - margin)))
    metadata = Image.Exif()
    metadata[36867] = captured_at.strftime("%Y:%m:%d %H:%M:%S")  # DateTimeOriginal
    offset = captured_at.strftime("%z")
    metadata[36881] = offset[:-2] + ":" + offset[-2:]  # OffsetTimeOriginal
    combined.save(target, format="JPEG", quality=85, exif=metadata)


def capture_cycle(cfg, watcher):
    if not allowed(watcher):
        log("Capture skipped: session locked, idle, or unavailable.")
        return
    if queue_size() >= cfg["max_queue_bytes"]:
        log("Capture paused: local queue is full; waiting for an upload.")
        return
    with tempfile.TemporaryDirectory(prefix="pending-", dir=STATE) as temporary:
        pending = Path(temporary)
        captured_at = datetime.now(CAPTURE_TIMEZONE)
        is_mac = isinstance(watcher, MacSession)
        screen = (["/usr/sbin/screencapture", "-x", "-m", "-t", "jpg", str(pending / "screen.jpg")]
                  if is_mac else ["grim", "-t", "jpeg", "-q", "80", str(pending / "screen.jpg")])
        camera = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
                  "-f", "avfoundation" if is_mac else "v4l2", "-video_size", cfg["video_size"]]
        for option in ("input_format", "framerate"):
            if cfg.get(option) is not None:
                camera += [f"-{option}", str(cfg[option])]
        camera += ["-i", cfg["device"], "-vf", "select=gte(n\\,30)",
                   "-frames:v", "1", "-q:v", "3", "-update", "1", "-y",
                   str(pending / "webcam.jpg")]
        images = {}
        for command, category in ((screen, "screen"), (camera, "webcam")):
            try:
                guarded(command, watcher, 15 if category == "screen" else 30)
                path = Path(command[-1])
                with Image.open(path) as image:
                    image.verify()
                images[category] = path
            except SessionInactive:
                log(f"{category} capture discarded: session became locked, idle, or unavailable.")
                break
            except (OSError, RuntimeError) as error:
                log(f"{category} capture unavailable: {error}")
        if not images:
            return
        combined = pending / "capture.jpg"
        compose_capture(images, combined, captured_at)
        size = combined.stat().st_size
        if size + queue_size() > cfg["max_queue_bytes"]:
            log("Capture discarded: it would exceed the local queue limit.")
            return
        stamp = captured_at.strftime("%Y-%m-%dT%H-%M-%S.%f%z")
        destination = QUEUE / captured_at.strftime("%Y-%m-%d")
        destination.mkdir(mode=0o700, parents=True, exist_ok=True)
        combined.replace(destination / f"{stamp}.jpg")
        log(f"Captured {stamp}.jpg ({'+'.join(images)}, {size} bytes).")


def upload(cfg):
    if not any(path.is_file() for path in QUEUE.rglob("*")):
        return
    ssh = ["ssh", "-oBatchMode=yes", "-oStrictHostKeyChecking=yes",
           "-oConnectTimeout=10", "-oServerAliveInterval=15", "-oServerAliveCountMax=2",
           "-oIdentityAgent=none", "-oIdentitiesOnly=yes", "-i",
           str(Path(cfg["identity_file"]).expanduser())]
    try:
        # rsync uses SSH, retries interrupted files and removes only acknowledged files.
        subprocess.run(
            ["rsync", "-rt", "--perms", "--remove-source-files", "--chmod=D2750,F640", "--timeout=60",
             "-e", shlex.join(ssh), f"{QUEUE}/", f"{cfg['remote']}:{cfg['remote_path']}/"],
            check=True, timeout=180,
        )
        log("Upload completed; acknowledged files removed from the local queue.")
    except (OSError, subprocess.SubprocessError) as error:
        log(f"Upload incomplete ({type(error).__name__}); queued files will be retried.")
    for directory in sorted(QUEUE.rglob("*"), key=lambda path: len(path.parts), reverse=True):
        if directory.is_dir() and not any(directory.iterdir()):
            directory.rmdir()


def run(cfg):
    os.umask(0o077)
    for directory in (STATE, QUEUE, RUNTIME):
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        directory.chmod(0o700)
    # The service, manual runs and sync must never upload/delete concurrently.
    with (STATE / "lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("activity-capture is already running") from None
        # A power loss may leave partial captures outside the queue.
        for pending in STATE.glob("pending-*"):
            if pending.is_dir():
                shutil.rmtree(pending)
        (RUNTIME / "idle").unlink(missing_ok=True)
        is_mac = platform.system() == "Darwin"
        watcher = MacSession(cfg) if is_mac else subprocess.Popen([
            "activity-idle-watch", str(cfg["idle_seconds"]), str(RUNTIME / "idle"),
        ])
        # Do not capture immediately on startup: let the idle watcher establish state.
        next_capture = time.monotonic() + max(cfg["interval_seconds"], cfg["idle_seconds"])
        next_upload = time.monotonic()
        try:
            while True:
                if watcher.poll() is not None:
                    raise RuntimeError("Idle watcher exited; refusing further captures")
                now = time.monotonic()
                if now >= next_capture:
                    try:
                        capture_cycle(cfg, watcher)
                    except (OSError, RuntimeError) as error:
                        log(str(error))
                    next_capture = max(now + cfg["interval_seconds"], time.monotonic())
                if now >= next_upload:
                    upload(cfg)
                    next_upload = time.monotonic() + 60
                time.sleep(1)
        finally:
            if not is_mac:
                watcher.terminate()
                try:
                    watcher.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    watcher.kill()
                    watcher.wait()
            (RUNTIME / "idle").unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["run", "start", "stop", "status", "permissions", "devices"])
    args = parser.parse_args()
    if args.command == "permissions":
        if platform.system() != "Darwin":
            parser.error("permissions is only needed on macOS")
        import Quartz
        import AVFoundation
        import threading
        print("Requesting Screen Recording and Camera access. Allow them in System Settings > Privacy & Security.", flush=True)
        Quartz.CGRequestScreenCaptureAccess()
        done = threading.Event()
        AVFoundation.AVCaptureDevice.requestAccessForMediaType_completionHandler_(
            AVFoundation.AVMediaTypeVideo, lambda granted: done.set())
        done.wait(60)
        print("If permissions were changed, restart the capture agent. Run devices to list camera indices.")
    elif args.command == "devices":
        if platform.system() != "Darwin":
            parser.error("Use v4l2-ctl --list-devices on Linux")
        subprocess.run(["ffmpeg", "-hide_banner", "-f", "avfoundation", "-list_devices", "true", "-i", ""])
    elif args.command in ("start", "stop", "status"):
        if platform.system() == "Darwin":
            label = f"gui/{os.getuid()}/org.nix-community.home.activity-capture"
            command = {"start": ["kickstart", label], "stop": ["bootout", label], "status": ["print", label]}[args.command]
            if args.command == "start":
                plist = Path.home() / "Library/LaunchAgents/org.nix-community.home.activity-capture.plist"
                subprocess.run(["/bin/launchctl", "bootstrap", f"gui/{os.getuid()}", str(plist)], check=False, capture_output=True)
            raise SystemExit(subprocess.run(["/bin/launchctl", *command]).returncode)
        raise SystemExit(subprocess.run(["systemctl", "--user", args.command, "activity-capture.service"]).returncode)
    else:
        # Unwind guarded captures and stop the child when systemd stops the service.
        def terminate(signum, frame):
            raise SystemExit(0)
        signal.signal(signal.SIGTERM, terminate)
        run(settings())


if __name__ == "__main__":
    main()
