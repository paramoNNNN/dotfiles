{
  config,
  lib,
  pkgs,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  darwinConfig = "${config.home.homeDirectory}/Library/Application Support/com.mitchellh.ghostty/config";
in
{
  programs.ghostty = {
    enable = true;
    package = lib.mkIf isDarwin null;
    enableFishIntegration = true;
    installBatSyntax = !isDarwin;
    installVimSyntax = !isDarwin;
    settings = {
      command = lib.getExe config.programs.fish.package;

      clipboard-paste-bracketed-safe = true;
      clipboard-paste-protection = true;
      clipboard-trim-trailing-spaces = true;

      font-size = 16;
      font-feature = [
        "ss02"
        "ss03"
        "ss04"
        "liga"
      ];
      font-thicken = true;
      font-thicken-strength = 0;

      adjust-cell-height = "20%";

      macos-titlebar-style = "hidden";
      window-padding-x = 0;
      window-padding-y = 0;
      window-padding-balance = "true";
      window-padding-color = "extend";
      window-colorspace = "display-p3";
      window-vsync = "true";
      window-theme = "ghostty";
      window-decoration = "auto";

      cursor-style-blink = true;
      cursor-text = lib.mkForce "cell-foreground";

      custom-shader = [ "${./cursor_glide.glsl}" ];
      custom-shader-animation = true;
      alpha-blending = "linear-corrected";
      cursor-opacity = 0;
    };

  };

  xdg.configFile."ghostty/config".target = lib.mkIf isDarwin darwinConfig;
}
