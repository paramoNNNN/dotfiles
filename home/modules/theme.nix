{ pkgs, ... }: {
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
        name = "CaskaydiaCove Nerd Font";
        package = pkgs.nerd-fonts.caskaydia-cove;
      };
      sansSerif = {
        name = "CaskaydiaCove Nerd Font";
        package = pkgs.nerd-fonts.caskaydia-cove;
      };
      monospace = {
        name = "CaskaydiaCove Nerd Font";
        package = pkgs.nerd-fonts.caskaydia-cove;
      };
    };
  };
}
