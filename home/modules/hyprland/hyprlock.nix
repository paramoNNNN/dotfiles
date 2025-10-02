{ config, ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      background = {
        blur_passes = 2;
        contrast = 0.8;
        brightness = 0.8;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };
      label = [
        {
          text = "$TIME";
          color = "rgba(216, 222, 233, 0.8)";
          font_family = "SF Compact Rounded SemiBold";
          font_size = "200";
          position = "0, -140";
          halign = "center";
          valign = "top";
          shadow_passes = "10";
          shadow_size = "3";
        }
        {
          text = ''cmd[update:43200000] date +"%A, %d %B %Y"'';
          color = "rgba(216, 222, 233, 0.8)";
          font_family = "SF Compact Rounded Medium";
          font_size = "40";
          position = "0, -120";
          halign = "center";
          valign = "top";
        }
      ];
      input-field = {
        placeholder_text = ''
          <span foreground="##${config.lib.stylix.colors.base05}"><i>󰌾  Logged in as </i><span foreground="##${config.lib.stylix.colors.base08}">$USER</span></span>'';
        fade_on_empty = false;
        hide_input = false;
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;
      };

    };
  };
}
