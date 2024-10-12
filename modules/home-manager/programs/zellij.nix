{
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    settings = {
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
