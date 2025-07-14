{ inputs, pkgs, ... }: {
  stylix = {
    enable = true;
    polarity = "light";
    base16Scheme =
      "${pkgs.base16-schemes}/share/themes/gruvbox-light-hard.yaml";

    image = ../../assets/View_of_Vent_in_the_Ventertal.jpg;

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
