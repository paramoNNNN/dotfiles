{
  config,
  lib,
  pkgs,
  ...
}:
let
  screenshotEditor = pkgs.writeShellScriptBin "screenshot-editor" ''
    mode="''${1:-region}"
    capture_dir="${config.home.homeDirectory}/Pictures/Screenshots"
    ${pkgs.coreutils}/bin/mkdir -p "$capture_dir"
    output="$capture_dir/$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S).png"

    case "$mode" in
      region)
        geometry="$(${pkgs.slurp}/bin/slurp)" || exit 0
        ;;
      window)
        geometry="$(${pkgs.hyprland}/bin/hyprctl activewindow -j \
          | ${lib.getExe pkgs.jq} -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        ;;
      *)
        exit 2
        ;;
    esac

    ${pkgs.grim}/bin/grim -g "$geometry" - \
      | ${lib.getExe pkgs.satty} \
        --filename - \
        --output-filename "$output" \
        --copy-command "${pkgs.wl-clipboard}/bin/wl-copy" \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --early-exit all \
        --notification-thumbnail screenshot \
        --fullscreen
  '';
in
{
  imports = [
    ../gtk.nix
    ../fuzzel.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprpaper.nix
  ];

  # Consistent cursor theme across all applications.
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
  };

  home.packages = [
    screenshotEditor
    pkgs.gpu-screen-recorder-gtk
  ];

  wayland.windowManager.hyprland = {
    xwayland.enable = true;
    configType = "lua";
  };

  xdg.configFile = {
    "hypr/hyprland.lua" = {
      source = ./hyprland.lua;
    };

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
