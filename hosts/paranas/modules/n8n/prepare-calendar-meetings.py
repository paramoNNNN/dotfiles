import json
import os
import re
import sys
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo


TEHRAN = ZoneInfo("Asia/Tehran")
ROUTINE_WORDS = re.compile(r"\b(daily|planning|retro(?:spective)?)\b", re.I)


def unfold_ics(value: str) -> list[str]:
    lines: list[str] = []
    for line in value.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if line.startswith((" ", "\t")) and lines:
            lines[-1] += line[1:]
        else:
            lines.append(line)
    return lines


def unescape(value: str) -> str:
    return (
        value.replace("\\n", "\n")
        .replace("\\N", "\n")
        .replace("\\,", ",")
        .replace("\\;", ";")
        .replace("\\\\", "\\")
    )


def parse_start(key: str, value: str) -> datetime:
    params = dict(
        part.split("=", 1) for part in key.split(";")[1:] if "=" in part
    )
    if params.get("VALUE") == "DATE" or len(value) == 8:
        return datetime.strptime(value[:8], "%Y%m%d").replace(tzinfo=TEHRAN)
    if value.endswith("Z"):
        return datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(
            tzinfo=timezone.utc
        ).astimezone(TEHRAN)
    parsed = datetime.strptime(value[:15], "%Y%m%dT%H%M%S")
    try:
        zone = ZoneInfo(params.get("TZID", "Asia/Tehran"))
    except Exception:
        zone = TEHRAN
    return parsed.replace(tzinfo=zone).astimezone(TEHRAN)


def slug(value: str) -> str:
    result = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return result[:70] or "meeting"


def missing_sections(note: str) -> list[str]:
    required = ["Agenda", "Notes", "Decisions", "Action items"]
    sections: dict[str, list[str]] = {name: [] for name in required}
    active: str | None = None
    for line in note.splitlines():
        heading = re.match(r"^##\s+(.+?)\s*$", line)
        if heading:
            active = heading.group(1) if heading.group(1) in sections else None
        elif active:
            sections[active].append(line)

    def meaningful(lines: list[str]) -> bool:
        for line in lines:
            value = line.strip()
            if value and value not in {"-", "- [ ]", "*", "* [ ]"}:
                return True
        return False

    return [name for name in required if not meaningful(sections[name])]


def main() -> None:
    url = os.environ.get("WORK_CALENDAR_ICS_URL", "")
    if not url:
        print(json.dumps({"meetings": [], "calendarConfigured": False}))
        return

    request = urllib.request.Request(url, headers={"User-Agent": "n8n-calendar/1"})
    with urllib.request.urlopen(request, timeout=30) as response:
        content = response.read().decode("utf-8-sig")

    events: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    for line in unfold_ics(content):
        if line == "BEGIN:VEVENT":
            current = {}
        elif line == "END:VEVENT" and current is not None:
            events.append(current)
            current = None
        elif current is not None and ":" in line:
            key, value = line.split(":", 1)
            current[key] = unescape(value)

    today = datetime.now(TEHRAN).date()
    first_day = today - timedelta(days=29)
    meetings_dir = Path(
        os.environ.get("OBSIDIAN_VAULT_ROOT", "/var/lib/obsidian-vault")
    ) / "Meetings"
    meetings_dir.mkdir(parents=True, exist_ok=True)
    meetings = []

    for event in events:
        start_key = next((key for key in event if key.startswith("DTSTART")), None)
        title = event.get("SUMMARY", "Untitled meeting").strip()
        if not start_key or ROUTINE_WORDS.search(title):
            continue
        start = parse_start(start_key, event[start_key])
        event_date = start.date()
        if not first_day <= event_date <= today:
            continue

        filename = f"{event_date.isoformat()}-{slug(title)}.md"
        relative_path = f"Meetings/{filename}"
        target = meetings_dir / filename
        created = False
        if not target.exists():
            note = "\n".join(
                [
                    "---",
                    "type: meeting",
                    f'date: "{event_date.isoformat()}"',
                    f'start: "{start.strftime("%H:%M")}"',
                    f'title: {json.dumps(title, ensure_ascii=False)}',
                    "---",
                    "",
                    f"# {title}",
                    "",
                    f"- **When:** {start.strftime('%Y-%m-%d %H:%M')} Asia/Tehran",
                    "",
                    "## Agenda",
                    "",
                    "- ",
                    "",
                    "## Notes",
                    "",
                    "## Decisions",
                    "",
                    "- ",
                    "",
                    "## Action items",
                    "",
                    "- [ ] ",
                    "",
                ]
            )
            try:
                with target.open("x", encoding="utf-8") as handle:
                    handle.write(note)
                created = True
            except FileExistsError:
                pass

        missing = missing_sections(target.read_text(encoding="utf-8"))
        if missing:
            meetings.append(
                {
                    "title": title,
                    "start": start.isoformat(),
                    "path": relative_path,
                    "created": created,
                    "missingSections": missing,
                }
            )

    meetings.sort(key=lambda meeting: meeting["start"])
    print(
        json.dumps(
            {
                "meetings": meetings,
                "calendarConfigured": True,
                "checkedFrom": first_day.isoformat(),
                "checkedThrough": today.isoformat(),
            }
        )
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Calendar processing failed: {error}", file=sys.stderr)
        raise
