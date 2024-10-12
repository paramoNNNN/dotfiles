{
  programs.alacritty = {
    enable = true;
    settings = {
      shell.program = "fish";
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

      window = {
        opacity = 0.9;
        padding = {
          x = 10;
          y = 0;
        };
      };
    };
  };
}

