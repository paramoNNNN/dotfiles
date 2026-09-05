{ config, lib, pkgs, ... }:
let
  calendarDirectory = "${config.xdg.dataHome}/calendars";
  mattermostDirectory = "${calendarDirectory}/mattermost";
  calendarFile = "${mattermostDirectory}/feed.ics";
  credentialsFile = "%h/.config/dms-calendar/mattermost.env";
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
  };

  programs.khal.enable = true;

  home.activation.ensurePersonalCalendar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/mkdir -p "${calendarDirectory}/personal"
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
