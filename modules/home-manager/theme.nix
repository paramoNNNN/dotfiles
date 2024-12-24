{ pkgs, inputs, ... }: {
  imports = [ inputs.catppuccin.homeManagerModules.catppuccin ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "blue";

    btop.enable = true;
    bat.enable = true;
    delta.enable = true;
    lazygit.enable = true;
    gtk = {
      enable = true;
      icon.enable = true;
      gnomeShellTheme = true;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
  };

  gtk = { enable = true; };
}
