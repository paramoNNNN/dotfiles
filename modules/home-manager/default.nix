{ ... }: {
  imports = [
    ./programs/alacritty.nix
    ./programs/bat.nix
    ./programs/btop.nix
    ./programs/direnv.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/lazygit.nix
    ./programs/nixvim
    ./programs/swaync.nix
    ./programs/tmux.nix
    ./programs/wofi.nix

    ./wm.nix
    ./theme.nix
  ];
}
