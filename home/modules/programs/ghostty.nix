{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      command = "fish";

      clipboard-paste-bracketed-safe = true;
      clipboard-paste-protection = true;
      clipboard-trim-trailing-spaces = true;

      font-size = 14;
      font-feature = [ "ss02" "ss03" "ss04" "liga" ];
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

      cursor-style-blink = true;
      cursor-invert-fg-bg = true;
    };

  };
}
