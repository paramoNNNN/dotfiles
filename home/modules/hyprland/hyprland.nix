{
  config,
  lib,
  pkgs,
  ...
}:
let
  screenshotPreview = pkgs.stdenvNoCC.mkDerivation {
    pname = "screenshot-preview";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.gobject-introspection ];
    buildInputs = [
      (pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ]))
      pkgs.gtk3
      pkgs.gtk-layer-shell
    ];
    installPhase = ''
      install -Dm755 ${./screenshot-preview.py} $out/bin/screenshot-preview
      patchShebangs $out/bin/screenshot-preview
    '';
  };
  screenshotEditor = pkgs.writeShellScriptBin "screenshot-editor" ''
    set -euo pipefail
    mode="''${1:-region}"

    if [ "$mode" = edit ]; then
      exec ${lib.getExe pkgs.satty} \
        --filename "$2" \
        --output-filename "$2" \
        --copy-command "${pkgs.wl-clipboard}/bin/wl-copy --type image/png" \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --early-exit all \
        --notification-thumbnail screenshot \
        --fullscreen
    fi

    # Dismiss the previous thumbnail before capturing again.
    ${screenshotPreview}/bin/screenshot-preview --dismiss
    capture_dir="${config.home.homeDirectory}/Pictures/Screenshots"
    ${pkgs.coreutils}/bin/mkdir -p "$capture_dir"

    case "$mode" in
      region)
        geometry="$(${pkgs.slurp}/bin/slurp)" || exit 0
        ;;
      window)
        geometry="$(${pkgs.hyprland}/bin/hyprctl activewindow -j \
          | ${lib.getExe pkgs.jq} -er 'select(.size[0] > 0 and .size[1] > 0) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        ;;
      *)
        exit 2
        ;;
    esac

    output="$(${pkgs.coreutils}/bin/mktemp "$capture_dir/$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S)-XXXXXX.png")"
    if ! ${pkgs.grim}/bin/grim -g "$geometry" "$output"; then
      ${pkgs.coreutils}/bin/rm -f "$output"
      exit 1
    fi
    ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$output"
    exec ${screenshotPreview}/bin/screenshot-preview "$output" "$0" edit "$output"
  '';
in
{
  imports = [
    ../gtk.nix
    ../fuzzel.nix
    ./hypridle.nix
    ./hyprpaper.nix
  ];

  # Consistent cursor theme across all applications.
  home.pointerCursor = {
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
        if [ "$HYPRGAMEMODE" = true ] || [ "$HYPRGAMEMODE" = 1 ]; then
            hyprctl eval 'hl.config({
                animations = { enabled = false },
                general = {
                    allow_tearing = true,
                    gaps_in = 0,
                    gaps_out = 0,
                    border_size = 1,
                },
                decoration = {
                    rounding = 0,
                    blur = { enabled = false },
                    shadow = { enabled = false },
                },
            })'
            exit
        fi
        hyprctl reload
      '';
      executable = true;
    };
  };
}
