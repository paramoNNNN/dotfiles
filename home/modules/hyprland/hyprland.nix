{ pkgs, ... }: {
  imports = [
    ../cliphist.nix
    ../gtk.nix
    ../swaync.nix
    ../waybar.nix
    ../fuzzel.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  # Consistent cursor theme across all applications.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.yaru-theme;
    name = "Yaru";
    size = 24;
  };

  wayland.windowManager.hyprland = { xwayland.enable = true; };

  xdg.configFile = {
    "hypr/hyprland.conf" = { source = ./hyprland.conf; };

    "hypr/gamemode.sh" = {
      text = ''
        #!/usr/bin/env sh
        HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
        if [ "$HYPRGAMEMODE" = 1 ] ; then
            hyprctl --batch "\
                keyword animations:enabled 0;\
                keyword decoration:shadow:enabled 0;\
                keyword decoration:blur:enabled 0;\
                keyword general:allow_tearing 1;\
                keyword general:gaps_in 0;\
                keyword general:gaps_out 0;\
                keyword general:border_size 1;\
                keyword decoration:rounding 0"
            exit
        fi
        hyprctl reload
      '';
      executable = true;
    };
  };
}
