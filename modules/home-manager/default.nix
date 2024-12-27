{ ... }: {
  imports = [
    ./programs/alacritty.nix
    ./programs/bat.nix
    ./programs/btop.nix
    ./programs/direnv.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/lazygit.nix
    ./programs/tmux.nix
    ./programs/nixvim
    ./programs/wofi.nix

    ./wm.nix
    ./theme.nix
  ];
}
