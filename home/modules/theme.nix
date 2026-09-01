{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  options.theme.variant = lib.mkOption {
    type = lib.types.enum [
      "dark"
      "light"
    ];
    default = "light";
    description = "The system-wide Flexoki color variant.";
  };

  config = {
    theme.variant = lib.mkDefault "light";

    stylix = {
      enable = true;
      polarity = config.theme.variant;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/flexoki-${config.theme.variant}.yaml";

      icons = {
        enable = true;
        light = "rose-pine-dawn";
        dark = "rose-pine";
        package = pkgs.rose-pine-icon-theme;
      };

      cursor = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      image = ../../assets/moon.jpg;

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
      };
    };
  };
}
