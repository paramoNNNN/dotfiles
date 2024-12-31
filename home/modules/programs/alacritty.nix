{ lib, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell.program = "fish";
      env.TERM = "xterm-256color";
      scrolling.history = 10000;

      font = {
        size = 18;
        offset.y = 6;
        glyph_offset.y = 3;
        bold = {
          family = "CaskaydiaCove Nerd Font";
          style = "SemiBold";
        };
        italic = {
          family = "CaskaydiaCove Nerd Font";
          style = "Italic";
        };
        normal = {
          family = "CaskaydiaCove Nerd Font";
          style = "Regular";
        };
      };

      colors.primary.background = lib.mkForce "#ffffff";

      window = {
        opacity = 0.9;
        blur = true;
        decorations = "Buttonless";
        padding = {
          x = 0;
          y = 0;
        };
        dynamic_padding = true;
      };
    };
  };
}
