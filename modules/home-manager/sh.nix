{ lib, pkgs, ... }:

{
  programs.bash = { enable = true; };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting;
      set fish_vi_key_bindings;
    '';
    plugins = [
      {
        name = "pure";
        src = pkgs.fetchFromGitHub {
          owner = "pure-fish";
          repo = "pure";
          "rev" = "28447d2e7a4edf3c954003eda929cde31d3621d2";
          "hash" = "sha256-8zxqPU9N5XGbKc0b3bZYkQ3yH64qcbakMsHIpHZSne4=";
        };
      }
      {
        name = "fish-abbreviation-tips";
        src = pkgs.fetchFromGitHub {
          "owner" = "gazorby";
          "repo" = "fish-abbreviation-tips";
          "rev" = "8ed76a62bb044ba4ad8e3e6832640178880df485";
          "hash" = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
        };
      }
      {
        name = "done";
        src = pkgs.fetchFromGitHub {
          "owner" = "franciscolourenco";
          "repo" = "done";
          "rev" = "eb32ade85c0f2c68cbfcff3036756bbf27a4f366";
          "hash" = "sha256-DMIRKRAVOn7YEnuAtz4hIxrU93ULxNoQhW6juxCoh4o=";
        };
      }
      {
        name = "autopair.fish";
        src = pkgs.fetchFromGitHub {
          "owner" = "jorgebucaran";
          "repo" = "autopair.fish";
          "rev" = "4d1752ff5b39819ab58d7337c69220342e9de0e2";
          "hash" = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
        };
      }
      {
        name = "plugin-git";
        src = pkgs.fetchFromGitHub {
          "owner" = "jhillyerd";
          "repo" = "plugin-git";
          "rev" = "e4897db7abd43a74c902b5000c535b9da6ff766e";
          "hash" = "sha256-p7vvwisu3mvVOE1DcALbzuGJqWBcE1h71UjaopGdxE0=";
        };
      }
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "85f863f20f24faf675827fb00f3a4e15c7838d76";
          sha256 = "sha256-+FUBM7CodtZrYKqU542fQD+ZDGrd2438trKM0tIESs0=";
        };
      }
    ];
    shellAliases = {
      ls = "exa --icons";
      go = "git open";
      nvim =
        "nvim --listen /tmp/nvim-server-(tmux display-message -p '#S-#{window_index}').pipe";
      cat = "bat --theme=base16";
    };
  };

  programs.alacritty = {
    enable = true;
    settings = lib.attrsets.recursiveUpdate (import ./programs/alacritty.nix) {
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

  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      default_shell = "fish";
      simplified_ui = true;
    };
  };
}
