{ ... }: {
  imports = [
    ./programs/alacritty.nix
    ./programs/delta.nix
    ./programs/fish.nix
    ./programs/lazygit.nix
    ./programs/zellij.nix

    ./wm.nix
    ./theme.nix
  ];
}
