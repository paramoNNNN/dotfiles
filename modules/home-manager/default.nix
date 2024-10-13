{ ... }: {
  imports = [
    ./programs/alacritty.nix
    ./programs/btop.nix
    ./programs/delta.nix
    ./programs/direnv.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/lazygit.nix
    ./programs/tmux.nix

    ./wm.nix
    ./theme.nix
  ];
}
