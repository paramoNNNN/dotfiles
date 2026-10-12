{
  services.hypridle = {
    enable = true;
    settings = {
      listener = [
        {
          timeout = 900; # 15 minutes
          on-timeout = ''
            loginctl lock-session
            sleep 1
            hyprctl dispatch dpms off || hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
          '';
          on-resume = ''
            hyprctl dispatch dpms on || hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
          '';
        }
      ];
    };
  };
}
