{
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      themes = {
        catppuccin-latte = {
          bg = "#acb0be";
          fg = "#acb0be";
          red = "#d20f39";
          green = "#40a02b";
          blue = "#1e66f5";
          yellow = "#df8e1d";
          magenta = "#ea76cb";
          orange = "#fe640b";
          cyan = "#04a5e5";
          black = "#dce0e8";
          white = "#4c4f69";
        };
      };
      theme = "catppuccin-latte";

      default_shell = "fish";
      default_layout = "compact";
      layout_dir = "./layouts";
      simplified_ui = true;
    };
  };

  home.file.zellij = {
    target = ".config/zellij/layouts/default.kdl";
    text = ''
      layout {
        pane {
          command "ping"
          args "1.1.1.1" "-i" "0.5"
        }
        pane split_direction="vertical" {
          pane {
            cwd "$HOME/ovpn"
          }
          pane {
            cwd "$HOME/xray"
          }
        }
      }
    '';
  };
}
