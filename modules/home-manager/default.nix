{ ... }: {
  imports = [
    ./programs/alacritty.nix
    ./programs/fish.nix
    ./programs/zellij.nix

    ./wm.nix
  ];
}
