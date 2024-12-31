{ inputs, ... }: {
  imports = [ inputs.catppuccin.homeManagerModules.catppuccin ];

  catppuccin = {
    enable = true;
    flavor = "latte";
    accent = "blue";

    btop.enable = true;
    bat.enable = true;
    delta.enable = true;
    tmux.enable = false;
    lazygit.enable = true;
  };
}
