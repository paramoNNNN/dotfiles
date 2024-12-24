{ pkgs, inputs, ... }: {
  imports = [ inputs.catppuccin.homeManagerModules.catppuccin ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "blue";

    bat = { enable = true; };

    delta = { enable = true; };
  };

  home.pointerCursor = {
    gtk.enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
  };

  gtk = {
    enable = true;
    catppuccin = {
      enable = true;
      icon.enable = true;
      gnomeShellTheme = true;
    };
  };
}
