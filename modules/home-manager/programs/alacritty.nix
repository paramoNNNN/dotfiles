{ lib, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell.program = "fish";
      env.TERM = "xterm-256color";
      scrolling.history = 10000;

      font = {
        size = 16;
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

      colors.primary.background = lib.mkForce "#000000";

      window = {
        opacity = 0.9;
        padding = {
          x = 0;
          y = 0;
        };
      };
    };
  };
}

