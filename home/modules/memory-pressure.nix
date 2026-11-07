{
  pkgs,
  lib,
  ...
}:
let
  monitor = import ../../packages/memory-pressure-monitor { inherit pkgs; };
in
{
  home.packages = [ monitor ];

  systemd.user.services.memory-pressure-watch = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "Memory pressure alerts and durable process diagnostics";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${monitor}/bin/memory-pressure-watch run";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

}
