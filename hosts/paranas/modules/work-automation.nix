{ pkgs, ... }:

let
  archiveObsidianNotes = pkgs.writeShellApplication {
    name = "archive-obsidian-notes";
    runtimeInputs = with pkgs; [
      coreutils
      diffutils
      findutils
      gawk
      jq
    ];
    text = builtins.readFile ./work-automation/archive-obsidian-notes.sh;
  };
  prepareCalendarMeetings = pkgs.writers.writePython3Bin "prepare-calendar-meetings" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./work-automation/prepare-calendar-meetings.py);
  briefSource = pkgs.runCommand "work-daily-brief-source" { } ''
    mkdir -p "$out"
    cp ${./work-automation/work-daily-brief.mjs} "$out/work-daily-brief.mjs"
    cp ${./work-automation/render-brief.mjs} "$out/render-brief.mjs"
  '';
  workDailyBrief = pkgs.writeShellApplication {
    name = "work-daily-brief";
    runtimeInputs = [ prepareCalendarMeetings ];
    text = ''
      exec ${pkgs.nodejs}/bin/node --max-old-space-size=256 ${briefSource}/work-daily-brief.mjs
    '';
  };
  jobs = {
    work-daily-brief = {
      description = "Write the previous day's GitLab and Plane briefing to Obsidian";
      command = "${workDailyBrief}/bin/work-daily-brief";
      calendar = "*-*-* 06:45:00 Asia/Tehran";
      secrets = true;
    };
    work-calendar-meetings = {
      description = "Prepare create-only Obsidian meeting notes from the calendar";
      command = "${prepareCalendarMeetings}/bin/prepare-calendar-meetings";
      calendar = "*-*-* *:00,30:00 Asia/Tehran";
      secrets = true;
    };
    work-archive-notes = {
      description = "Archive Obsidian notes from the previous Saturday through Friday";
      command = "${archiveObsidianNotes}/bin/archive-obsidian-notes";
      calendar = "Sat *-*-* 00:15:00 Asia/Tehran";
      secrets = false;
    };
  };
in
{
  users.groups.work-automation = { };
  users.users.work-automation = {
    isSystemUser = true;
    group = "work-automation";
    extraGroups = [ "obsidian-vault" ];
  };

  systemd.tmpfiles.rules = [
    "d /run/work-automation 0750 work-automation work-automation -"
  ];

  systemd.services = builtins.mapAttrs (_: job: {
    inherit (job) description;
    requires = [ "obsidian-vault-permissions.service" ];
    after = [
      "network-online.target"
      "obsidian-vault-permissions.service"
    ];
    wants = [ "network-online.target" ];
    environment = {
      OBSIDIAN_VAULT_ROOT = "/var/lib/obsidian-vault";
      TZ = "Asia/Tehran";
      TZDIR = "${pkgs.tzdata}/share/zoneinfo";
      PYTHONTZPATH = "${pkgs.tzdata}/share/zoneinfo";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "work-automation";
      Group = "work-automation";
      SupplementaryGroups = [ "obsidian-vault" ];
      # Reuse the root-owned environment file; no credentials need copying.
      EnvironmentFile = if job.secrets then [ "/var/lib/n8n-secrets/environment" ] else [ ];
      ExecStart = "${pkgs.util-linux}/bin/flock --wait 600 /run/work-automation/vault.lock ${job.command}";
      TimeoutStartSec = "20min";
      UMask = "0007";
      MemoryHigh = "384M";
      MemoryMax = "512M";
      TasksMax = 64;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/var/lib/obsidian-vault"
        "/run/work-automation"
      ];
    };
  }) jobs;

  systemd.timers = builtins.mapAttrs (_: job: {
    inherit (job) description;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = job.calendar;
      Persistent = true;
      AccuracySec = "1min";
    };
  }) jobs;

  environment.systemPackages = [
    archiveObsidianNotes
    prepareCalendarMeetings
    workDailyBrief
  ];
}
