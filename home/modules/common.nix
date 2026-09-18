{
  config,
  inputs,
  lib,
  outputs,
  ...
}:
{
  imports = [
    ./programs/ghostty/default.nix
    ./programs/bat.nix
    ./programs/btop.nix
    ./programs/direnv.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/lazygit.nix
    ./programs/tmux.nix
    ./programs/nixvim/default.nix
    ./home.nix
    ./theme.nix
  ];

  programs.home-manager.path = "${inputs.home-manager}";
  home.packages = lib.optional config.submoduleSupport.enable config.programs.home-manager.package;
  news.display = "silent";

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [ outputs.overlays.stable-packages ];

    config = {
      allowUnfree = true;
    };
  };
}
