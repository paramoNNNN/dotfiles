{ pkgs, inputs, ... }:
let
  tmux-sensible = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-sensible";
    version = "v3.0.0";
    src = pkgs.fetchFromGitHub {
      "owner" = "tmux-plugins";
      "repo" = "tmux-sensible";
      "rev" = "25cb91f42d020f675bb0a2ce3fbd3a5d96119efa";
      "hash" = "sha256-sw9g1Yzmv2fdZFLJSGhx1tatQ+TtjDYNZI5uny0+5Hg=";
    };
  };
in {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    escapeTime = 10;
    historyLimit = 50000;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmux-sensible
      inputs.minimal-tmux.packages.${pkgs.system}.default
    ];

    extraConfig = ''
      set-option -g mouse on
      set -g renumber-windows on

      # Start numbering from 1 instead of 0
      set -g base-index 1
      setw -g pane-base-index 1

      # Auto rename window
      set-option -g status-interval 5
      set-option -g automatic-rename on
      set-option -g automatic-rename-format '#{b:pane_current_path}'

      # Move status bar to top/bottom
      bind-key C-k run-shell "tmux set-option -g status-position top;"
      bind-key C-j run-shell "tmux set-option -g status-position bottom;"

      # Setting tmux color modes 
      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Binds
      set-option -g prefix C-a
      unbind C-b
      bind-key C-a send-prefix
      bind-key t set-option -g status
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
    '';
  };

  home.file.teamocil = {
    target = ".teamocil/default.yml";
    text = ''
      name: default
      windows:
        - name: network
          root: ~/
          layout: main-vertical
          panes:
            - ping 1.1.1.1 -i 0.5
            - cd ~/ovpn
            - cd ~/xray
    '';
  };

}
