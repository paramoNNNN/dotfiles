{ config, ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      background = {
        blur_passes = 3;
        contrast = 0.8;
        brightness = 0.8;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };
      label = [
        {
          text = "$TIME";
          color = "rgb(${config.lib.stylix.colors.base00})";
          font_size = "90";
          position = "0, -50";
          halign = "center";
          valign = "top";
        }
        {
          text = ''cmd[update:43200000] date +"%A, %d %B %Y"'';
          color = "rgb(${config.lib.stylix.colors.base00})";
          font_size = "25";
          position = "0, -200";
          halign = "center";
          valign = "top";
        }
      ];
      input-field = {
        placeholder_text = ''
          <span foreground="##${config.lib.stylix.colors.base07}"><i>󰌾  Logged in as </i><span foreground="##${config.lib.stylix.colors.base0D}">$USER</span></span>'';
        fade_on_empty = false;
        hide_input = false;
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;
      };

    };
  };
}
