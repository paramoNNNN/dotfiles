{ config, lib, pkgs, ... }:
let
  calendarDirectory = "${config.xdg.dataHome}/calendars";
  mattermostDirectory = "${calendarDirectory}/mattermost";
  calendarFile = "${mattermostDirectory}/feed.ics";
  credentialsFile = "%h/.config/dms-calendar/mattermost.env";
  icloudCredentialsDirectory = "${config.xdg.configHome}/vdirsyncer";
  icloudUsernameFile = "${icloudCredentialsDirectory}/icloud-username";
  icloudPasswordFile = "${icloudCredentialsDirectory}/icloud-password";
  calendarPython = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.icalendar ]);
  splitIcsFeed = pkgs.writeText "split-ics-feed.py" ''
    import hashlib
    import pathlib
    import sys
    from icalendar import Calendar

    source = pathlib.Path(sys.argv[1])
    destination = pathlib.Path(sys.argv[2])
    destination.mkdir(parents=True, exist_ok=True)

    feed = Calendar.from_ical(source.read_bytes())
    shared = [component for component in feed.subcomponents if component.name == "VTIMEZONE"]
    events = {}
    for component in feed.subcomponents:
        if component.name == "VEVENT":
            uid = str(component.get("UID", "missing-uid"))
            events.setdefault(uid, []).append(component)

    for old_file in destination.glob("*.ics"):
        old_file.unlink()

    for uid, components in events.items():
        calendar = Calendar()
        calendar.add("prodid", "-//DMS Mattermost calendar sync//EN")
        calendar.add("version", "2.0")
        for component in shared + components:
            calendar.add_component(component)
        filename = hashlib.sha256(uid.encode()).hexdigest() + ".ics"
        (destination / filename).write_bytes(calendar.to_ical())
  '';

  syncCalendar = pkgs.writeShellScript "sync-mattermost-calendar" ''
    set -eu
    umask 077

    ${pkgs.coreutils}/bin/mkdir -p "${mattermostDirectory}"
    temporary_file="${calendarFile}.tmp"

    ${pkgs.curl}/bin/curl \
      --fail \
      --silent \
      --show-error \
      --location \
      --output "$temporary_file" \
      "$ICS_URL"

    ${calendarPython}/bin/python ${splitIcsFeed} "$temporary_file" "${mattermostDirectory}"
    ${pkgs.coreutils}/bin/rm "$temporary_file"
  '';
  nextEvent = pkgs.writers.writePython3Bin "dms-next-event" {
    flakeIgnore = [ "E501" ];
  } ''
    import datetime
    import json
    import subprocess

    now = datetime.datetime.now()
    command = [
        "${lib.getExe' pkgs.khal "khal"}", "list", "--once", "--notstarted",
        "--json", "title", "--json", "start-date", "--json", "start-time",
        "--json", "all-day", "now", "8h",
    ]

    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=20)
        events = []
        for line in result.stdout.splitlines():
            if line.strip():
                events.extend(json.loads(line))

        upcoming = []
        for event in events:
            if event.get("all-day") == "True" or not event.get("start-time"):
                continue
            start = datetime.datetime.strptime(
                f"{event['start-date']} {event['start-time']}",
                "%Y-%m-%d %H:%M:%S",
            )
            if start.date() == now.date() and start > now:
                upcoming.append((start, event.get("title") or "Untitled event"))

        if upcoming:
            start, title = min(upcoming, key=lambda item: item[0])
            print(json.dumps({
                "title": title,
                "remainingSeconds": max(1, int((start - now).total_seconds())),
            }, ensure_ascii=False))
        else:
            print(json.dumps({"title": "", "remainingSeconds": 0}))
    except Exception:
        print(json.dumps({"title": "", "remainingSeconds": 0}))
  '';
in
{
  accounts.calendar = {
    basePath = calendarDirectory;
    accounts.personal = {
      primary = true;
      local = {
        type = "filesystem";
        path = "${calendarDirectory}/personal";
      };
      khal = {
        enable = true;
        color = "dark green";
      };
    };
    accounts.mattermost = {
      local = {
        type = "filesystem";
        path = mattermostDirectory;
      };
      khal = {
        enable = true;
        readOnly = true;
        color = "light blue";
      };
    };
    # Keep the sync storage separate from khal's discovery view. Vdirsyncer
    # creates one subdirectory per discovered CalDAV collection in this root.
    accounts.icloud = {
      local = {
        type = "filesystem";
        path = "${calendarDirectory}/icloud";
      };
      remote = {
        type = "caldav";
        url = "https://caldav.icloud.com/";
        passwordCommand = [ "${pkgs.coreutils}/bin/cat" icloudPasswordFile ];
      };
      vdirsyncer = {
        enable = true;
        userNameCommand = [ "${pkgs.coreutils}/bin/cat" icloudUsernameFile ];
        collections = [ "from a" ];
        conflictResolution = "remote wins";
        metadata = [
          "color"
          "displayname"
        ];
      };
    };
    accounts.icloudCalendars = {
      local = {
        type = "filesystem";
        path = "${calendarDirectory}/icloud";
      };
      khal = {
        enable = true;
        type = "discover";
        color = "dark blue";
      };
    };
  };

  programs.khal = {
    enable = true;
    locale = {
      dateformat = "%Y-%m-%d";
      longdateformat = "%Y-%m-%d";
      timeformat = "%H:%M:%S";
      datetimeformat = "%Y-%m-%d %H:%M:%S";
      longdatetimeformat = "%Y-%m-%d %H:%M:%S";
    };
  };
  programs.vdirsyncer.enable = true;
  services.vdirsyncer = {
    enable = true;
    frequency = "*:0/15";
  };
  home.packages = [ nextEvent ];

  home.activation.ensurePersonalCalendar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/mkdir -p "${calendarDirectory}/personal"
    run ${pkgs.coreutils}/bin/mkdir -p "${calendarDirectory}/icloud"
    # Older configuration treated %s as a literal directory. Preserve its
    # downloaded data while moving each collection to the corrected root.
    if [ -d "${calendarDirectory}/icloud/%s" ]; then
      run ${pkgs.coreutils}/bin/cp -an \
        "${calendarDirectory}/icloud/%s/." \
        "${calendarDirectory}/icloud/"
    fi
  '';

  systemd.user = {
    services.dms-calendar-sync = {
      Unit = {
        Description = "Synchronize the Mattermost ICS calendar for DMS";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        ConditionPathExists = credentialsFile;
      };
      Service = {
        Type = "oneshot";
        EnvironmentFile = credentialsFile;
        ExecStart = syncCalendar;
      };
    };

    timers.dms-calendar-sync = {
      Unit.Description = "Periodically synchronize the Mattermost ICS calendar";
      Timer = {
        OnBootSec = "1m";
        OnUnitActiveSec = "15m";
        Persistent = true;
        Unit = "dms-calendar-sync.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
