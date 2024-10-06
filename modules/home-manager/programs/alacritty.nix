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

      colors = {
        indexed_colors = [
          {
            color = "#FE640B";
            index = 16;
          }
          {
            color = "#DC8A78";
            index = 17;
          }
        ];
        bright = {
          black = "#6C6F85";
          blue = "#1E66F5";
          cyan = "#179299";
          green = "#40A02B";
          magenta = "#EA76CB";
          red = "#D20F39";
          white = "#BCC0CC";
          yellow = "#DF8E1D";
        };
        cursor = {
          cursor = "#DC8A78";
          text = "#EFF1F5";
        };
        dim = {
          black = "#5C5F77";
          blue = "#1E66F5";
          cyan = "#179299";
          green = "#40A02B";
          magenta = "#EA76CB";
          red = "#D20F39";
          white = "#ACB0BE";
          yellow = "#DF8E1D";
        };
        hints = {
          end = {
            background = "#6C6F85";
            foreground = "#EFF1F5";
          };
          start = {
            background = "#DF8E1D";
            foreground = "#EFF1F5";
          };
        };
        normal = {
          black = "#5C5F77";
          blue = "#1E66F5";
          cyan = "#179299";
          green = "#40A02B";
          magenta = "#EA76CB";
          red = "#D20F39";
          white = "#ACB0BE";
          yellow = "#DF8E1D";
        };
        primary = {
          background = "#EFF1F5";
          bright_foreground = "#4C4F69";
          dim_foreground = "#4C4F69";
          foreground = "#4C4F69";
        };
        search = {
          focused_match = {
            background = "#40A02B";
            foreground = "#EFF1F5";
          };
          matches = {
            background = "#6C6F85";
            foreground = "#EFF1F5";
          };
        };
        selection = {
          background = "#DC8A78";
          text = "#EFF1F5";
        };
        vi_mode_cursor = {
          cursor = "#7287FD";
          text = "#EFF1F5";
        };
      };
    };
  };
}

