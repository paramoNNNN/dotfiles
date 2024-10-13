{ ... }: {
  imports = [
    ./programs/alacritty.nix
    ./programs/delta.nix
    ./programs/fish.nix
    ./programs/lazygit.nix
    ./programs/tmux.nix

    ./wm.nix
    ./theme.nix
  ];
}
