{
  services.hypridle = {
    enable = true;
    settings = {
      listener = [
        {
          timeout = 900; # 15 minutes
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1200; # 20 minutes
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
