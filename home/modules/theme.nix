{ inputs, pkgs, ... }: {
  stylix = {
    enable = true;
    polarity = "light";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/chicago-day.yaml";
    override = { base0E = "#EB3D7E"; };

    ## good ## 
    # sakura -- not bad pink
    # chicago-day -- green/blue ish
    # atelier-cave-light -- pink 
    # atelier-heath-light -- better pink

    image = ../../assets/ghibli-japanese-walled-garden.png;

    targets = {
      nixvim = {
        transparentBackground = {
          main = true;
          numberLine = true;
          signColumn = true;
        };
      };
    };

    fonts = {
      serif = {
        name = "SF Compact Rounded";
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-compact;
      };
      sansSerif = {
        name = "SF Compact Rounded";
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-compact;
      };
      monospace = {
        name = "CaskaydiaCove Nerd Font";
        package = pkgs.nerd-fonts.caskaydia-cove;
      };
      emoji = {
        name = "Apple Color Emoji";
        package = inputs.apple-emoji.packages.${pkgs.system}.apple-emoji-linux;
      };
    };
  };
}
