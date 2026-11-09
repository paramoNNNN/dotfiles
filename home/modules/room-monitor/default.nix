{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.pillow ]);
  monitor = pkgs.writeShellApplication {
    name = "room-monitor";
    runtimeInputs = [ pkgs.ffmpeg pkgs.libnotify pkgs.systemd pkgs.xdg-utils ];
    text = ''
      exec ${python}/bin/python3 ${./monitor.py} "$@"
    '';
  };
in
{
  home.packages = [ monitor pkgs.v4l-utils ];

  # Deliberately no WantedBy: monitoring must be explicitly armed each session.
  systemd.user.services.room-monitor = {
    Unit.Description = "Webcam room-change monitor (manually armed)";
    Service = {
      ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep --mode=block --why=Room-monitor-is-armed ${monitor}/bin/room-monitor run";
      ExecStopPost = "${monitor}/bin/room-monitor clear-reference";
      UMask = "0077";
      KillMode = "mixed";
      TimeoutStopSec = 10;
    };
  };
  systemd.user.services.room-monitor-cleanup = {
    Unit.Description = "Remove room-monitor photos and videos older than 24 hours";
    Service = {
      Type = "oneshot";
      ExecStart = "${monitor}/bin/room-monitor cleanup";
      UMask = "0077";
    };
  };
  systemd.user.timers.room-monitor-cleanup = {
    Unit.Description = "Expire room-monitor photos and videos, including while disarmed";
    Timer = {
      OnStartupSec = "1m";
      OnUnitActiveSec = "5m";
      AccuracySec = "10s";
    };
    Install.WantedBy = [ "timers.target" ];
  };
  xdg.desktopEntries.room-monitor-arm = {
    name = "Arm Room Monitor";
    exec = "${monitor}/bin/room-monitor arm";
    icon = "camera-web";
    categories = [ "Utility" ];
  };
  xdg.desktopEntries.room-monitor-disarm = {
    name = "Disarm Room Monitor";
    exec = "${monitor}/bin/room-monitor disarm";
    icon = "camera-web";
    categories = [ "Utility" ];
  };
  xdg.desktopEntries.room-monitor-photos = {
    name = "Room Monitor Photos";
    exec = "${monitor}/bin/room-monitor photos";
    icon = "folder-pictures";
    categories = [ "Utility" ];
  };
  xdg.desktopEntries.room-monitor-videos = {
    name = "Room Monitor Videos";
    exec = "${monitor}/bin/room-monitor videos";
    icon = "folder-videos";
    categories = [ "Utility" ];
  };
}
