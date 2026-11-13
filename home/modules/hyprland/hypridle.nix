{ pkgs, ... }:
let
  displayOff = pkgs.writeShellScript "locked-screen-off" ''
    exec ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
  '';
  displayOn = pkgs.writeShellScript "locked-screen-wake" ''
    exec ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
  '';
  lockedIdleConfig = pkgs.writeText "locked-screen-idle.conf" ''
    timeout 5 '${displayOff}' resume '${displayOn}'
  '';
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Start the short idle timer only once the compositor confirms the lock.
        on_lock_cmd = "${pkgs.systemd}/bin/systemctl --user restart locked-screen-idle.service";
        on_unlock_cmd = "${pkgs.systemd}/bin/systemctl --user stop locked-screen-idle.service";
      };
      listener = [
        {
          timeout = 900; # 15 minutes
          on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
        }
      ];
    };
  };

  # No WantedBy: this timer runs only while the screen is locked. A separate
  # timer also gives an automatic lock its full five seconds before blanking.
  systemd.user.services.locked-screen-idle = {
    Unit = {
      Description = "Turn off the locked display after five seconds of inactivity";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w -C ${lockedIdleConfig}";
      ExecStopPost = "${displayOn}";
      Restart = "on-failure";
    };
  };
}
