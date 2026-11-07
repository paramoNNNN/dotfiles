{
  pkgs,
  lib,
  config,
  ...
}:
let
  isMac = pkgs.stdenv.hostPlatform.isDarwin;
  python = pkgs.python3.withPackages (
    ps:
    [
      ps.pillow
      ps.tzdata
    ]
    ++ lib.optionals isMac [
      ps.pyobjc-framework-Quartz
      ps.pyobjc-framework-AVFoundation
    ]
  );
  idleWatch = pkgs.stdenv.mkDerivation {
    pname = "activity-idle-watch";
    version = "1";
    dontUnpack = true;
    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.wayland-scanner
    ];
    buildInputs = [ pkgs.wayland ];
    buildPhase = ''
      protocol=${pkgs.wayland-protocols}/share/wayland-protocols/staging/ext-idle-notify/ext-idle-notify-v1.xml
      wayland-scanner client-header "$protocol" idle-notify.h
      wayland-scanner private-code "$protocol" idle-notify.c
      $CC -Wall -Wextra -Werror ${./idle-watch.c} idle-notify.c -I. \
        $(pkg-config --cflags --libs wayland-client) -o activity-idle-watch
    '';
    installPhase = ''
      install -Dm755 activity-idle-watch $out/bin/activity-idle-watch
    '';
  };
  capture = pkgs.writeShellApplication {
    name = "activity-capture";
    runtimeInputs = [
      pkgs.ffmpeg
      pkgs.openssh
      pkgs.rsync
    ]
    ++ lib.optionals (!isMac) [
      pkgs.grim
      pkgs.hyprland
      idleWatch
      pkgs.systemd
    ];
    text = ''
      exec ${python}/bin/python3 ${./capture.py} "$@"
    '';
  };
in
{
  home.packages = [ capture ];

  xdg.configFile."activity-capture/defaults.json".text = builtins.toJSON {
    interval_seconds = 900;
    idle_seconds = 300;
    max_queue_bytes = 1073741824;
    device = if isMac then "0:none" else "/dev/v4l/by-path/pci-0000:00:14.0-usb-0:2.3:1.0-video-index0";
    video_size = "640x480";
    input_format = if isMac then null else "yuyv422";
    framerate = if isMac then 30 else 15;
    remote = "paranas@192.168.1.215";
    remote_path = "/storage/activity-captures/${if isMac then "taha-mac" else "taha-pc"}";
    identity_file = "~/.ssh/activity_capture_ed25519";
  };

  systemd.user.services.activity-capture = lib.mkIf (!isMac) {
    Unit = {
      Description = "Screen and webcam archive while the Hyprland session is active";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${capture}/bin/activity-capture run";
      Restart = "on-failure";
      RestartSec = 15;
      RuntimeDirectory = "activity-capture";
      RuntimeDirectoryMode = "0700";
      UMask = "0077";
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  launchd.agents.activity-capture = lib.mkIf isMac {
    enable = true;
    config = {
      ProgramArguments = [
        "${capture}/bin/activity-capture"
        "run"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      LimitLoadToSessionType = "Aqua";
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/activity-capture.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/activity-capture.log";
    };
  };
}
