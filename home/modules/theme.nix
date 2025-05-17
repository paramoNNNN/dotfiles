{ inputs, ... }: {
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    flavor = "latte";
    accent = "sapphire";

    btop.enable = true;
    bat.enable = true;
    delta.enable = true;
    tmux.enable = false;
    lazygit.enable = true;
    waybar.enable = true;
  };
}
