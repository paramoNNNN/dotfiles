{ ... }: {
  imports = [
    ./programs/alacritty.nix
    ./programs/fish.nix
    ./programs/lazygit.nix
    ./programs/zellij.nix

    ./wm.nix
  ];
}
