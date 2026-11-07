"""Memory pressure notifications and durable, bounded diagnostics for Linux."""

import argparse
from collections import deque
from datetime import datetime, timezone
import fcntl
import heapq
import json
import os
from pathlib import Path
import subprocess
import time


STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "memory-pressure-watch"
INTERVAL = 5
LOG_LIMIT = 8 * 1024 * 1024
LOG_BACKUPS = 4


def boot_id():
    return Path("/proc/sys/kernel/random/boot_id").read_text().strip()


def parse_psi(text):
    result = {}
    for line in text.splitlines():
        kind, *fields = line.split()
        result[kind] = {key: float(value) for key, value in (field.split("=") for field in fields)}
    return result


def linux_sample():
    memory = {line.split(":")[0]: int(line.split()[1]) * 1024
              for line in Path("/proc/meminfo").read_text().splitlines()}
    psi = parse_psi(Path("/proc/pressure/memory").read_text())
    processes = []
    page_size = os.sysconf("SC_PAGE_SIZE")
    for directory in Path("/proc").iterdir():
        if not directory.name.isdigit():
            continue
        try:
            stat = (directory / "stat").read_text()
            start, end = stat.index("("), stat.rindex(")")
            fields = stat[end + 2:].split()
            rss = int(fields[21]) * page_size
            if rss > 0:
                processes.append({"pid": int(directory.name), "ppid": int(fields[1]),
                                  "name": stat[start + 1:end], "rss_bytes": rss})
        except (OSError, ValueError, IndexError):
            continue  # Processes can exit while /proc is being scanned.
    return {"platform": "Linux", "total_bytes": memory["MemTotal"],
            "available_bytes": memory["MemAvailable"],
            "swap_used_bytes": memory["SwapTotal"] - memory["SwapFree"],
            "psi": psi, "top": heapq.nlargest(15, processes, key=lambda p: p["rss_bytes"]),
            "vmstat": {key: int(value) for key, value in
                       (line.split() for line in Path("/proc/vmstat").read_text().splitlines())
                       if key in ("pgmajfault", "oom_kill", "pswpin", "pswpout")}}


def severity(sample):
    available = 100 * sample["available_bytes"] / sample["total_bytes"]
    some = sample["psi"]["some"]["avg10"]
    full = sample["psi"]["full"]["avg10"]
    if available <= 5 or full >= 10:
        return "critical"
    if available <= 10 or some >= 10:
        return "warning"
    return "normal"


def sample(previous=None):
    result = linux_sample()
    result.update(timestamp=datetime.now(timezone.utc).isoformat(), epoch=time.time(), boot_id=boot_id())
    result["used_percent"] = round(100 * (1 - result["available_bytes"] / result["total_bytes"]), 1)
    result["severity"] = severity(result)
    # A short stall can be diluted in avg10. Preserve interval pressure as evidence too.
    if previous and "psi" in result and previous.get("boot_id") == result["boot_id"]:
        elapsed = result["epoch"] - previous["epoch"]
        if elapsed > 0:
            result["interval_psi"] = {
                kind: round(max(0, min(100, (result["psi"][kind]["total"] - previous["psi"][kind]["total"]) / (elapsed * 10000))), 2)
                for kind in ("some", "full")
            }
            if result["interval_psi"]["full"] >= 10:
                result["severity"] = "critical"
            elif result["interval_psi"]["some"] >= 10 and result["severity"] == "normal":
                result["severity"] = "warning"
    return result


def save(record):
    target = STATE / "samples.jsonl"
    if target.exists() and target.stat().st_size >= LOG_LIMIT:
        (STATE / f"samples.jsonl.{LOG_BACKUPS}").unlink(missing_ok=True)
        for number in range(LOG_BACKUPS - 1, 0, -1):
            old = STATE / f"samples.jsonl.{number}"
            if old.exists():
                old.replace(STATE / f"samples.jsonl.{number + 1}")
        target.replace(STATE / "samples.jsonl.1")
    encoded = json.dumps(record, separators=(",", ":")) + "\n"
    with target.open("a") as output:
        output.write(encoded)
        output.flush()
        os.fsync(output.fileno())  # Preserve recent evidence through a forced reboot.
    temporary = STATE / "status.tmp"
    temporary.write_text(encoded)
    temporary.replace(STATE / "status.json")


def status():
    try:
        record = json.loads((STATE / "status.json").read_text())
        if time.time() - record["epoch"] > 20 or record["boot_id"] != boot_id():
            raise ValueError("Stale sample")
        return record
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        return {"severity": "unknown", "used_percent": None, "top": []}


def notify(record):
    title = "Memory pressure: " + record["severity"]
    available = record["available_bytes"] / 1024**3
    largest = ", ".join(f"{p['name']} (PID {p['pid']}): {p['rss_bytes'] / 1024**3:.1f} GiB" for p in record["top"][:3])
    body = f"{available:.1f} GiB available. Largest processes: {largest}. Diagnostics saved."
    # Use plain notification text; process names must not become markup.
    import html
    args = ["notify-send", "--app-name=Memory Pressure", "--icon=dialog-warning",
            "--urgency=" + ("critical" if record["severity"] == "critical" else "normal"),
            "--expire-time=" + ("0" if record["severity"] == "critical" else "15000"),
            title, html.escape(body)]
    try:
        subprocess.run(args, check=True, capture_output=True, timeout=3)
        return True
    except (OSError, subprocess.SubprocessError):
        return False


def run():
    os.umask(0o077)
    STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
    STATE.chmod(0o700)
    with (STATE / "lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("Memory monitor is already running") from None
        previous = None
        notified_level, last_notification = "normal", float("-inf")
        healthy_samples = 0
        ranks = {"unknown": -1, "normal": 0, "warning": 1, "critical": 2}
        while True:
            started = time.monotonic()
            try:
                record = sample(previous)
                save(record)
                previous = record
                level = record["severity"]
                healthy_samples = healthy_samples + 1 if level == "normal" else 0
                if healthy_samples >= 6:
                    notified_level = "normal"
                if level in ("warning", "critical"):
                    if ranks[level] > ranks[notified_level] or started - last_notification >= 180:
                        if notify(record):
                            notified_level, last_notification = level, started
                        else:
                            # Retry shortly without launching a failing notifier every sample.
                            notified_level = level
                            last_notification = started - 150
            except (OSError, ValueError, KeyError, AttributeError, subprocess.SubprocessError) as error:
                print(f"Memory sampling failed: {type(error).__name__}: {error}", flush=True)
            time.sleep(max(0.1, INTERVAL - (time.monotonic() - started)))


def report(previous_boot=False):
    current_boot = boot_id()
    records = deque(maxlen=20)
    selected_boot = None
    # Newest file first, but preserve chronological ordering within the selected tail.
    for suffix in ("", *(f".{n}" for n in range(1, LOG_BACKUPS + 1))):
        path = STATE / f"samples.jsonl{suffix}"
        if not path.exists():
            continue
        candidates = deque(maxlen=20)
        with path.open() as source:
            lines = list(source)
        for line in lines:
            try:
                record = json.loads(line)
                if previous_boot and record["boot_id"] == current_boot:
                    continue
                # Select the most recent recorded boot in this file.
                if selected_boot != record["boot_id"]:
                    candidates.clear()
                    selected_boot = record["boot_id"]
                candidates.append(record)
            except (ValueError, KeyError):
                continue  # The final line may have been interrupted by power loss.
        if candidates:
            records = candidates
            break
    if not records:
        print("No matching samples yet. Logs: " + str(STATE))
    for record in records:
        print(f"{record['timestamp']} {record['severity']} RAM {record['used_percent']}% "
              f"swap {record['swap_used_bytes']} PSI {record.get('psi', record.get('native_pressure'))}")
        for process in record["top"][:5]:
            print(f"  PID {process['pid']} parent {process['ppid']} {process['name']}: "
                  f"{process['rss_bytes'] / 1024**2:.0f} MiB")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["run", "sample", "status", "report"])
    parser.add_argument("--previous", action="store_true", help="Report the most recent recorded earlier boot")
    args = parser.parse_args()
    if args.command == "run":
        run()
    elif args.command == "sample":
        print(json.dumps(sample()))
    elif args.command == "status":
        print(json.dumps(status()))
    else:
        report(args.previous)


if __name__ == "__main__":
    main()
