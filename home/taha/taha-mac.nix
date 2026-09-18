{ lib, ... }:
{
  imports = [
    ../modules/aerospace.nix
    ../modules/common.nix
    ../modules/programs/obsidian.nix
  ];

  programs.home-manager.enable = true;

  # Prefer Nix commands after the system Fish config runs brew shellenv.
  programs.fish.interactiveShellInit = lib.mkAfter ''
    fish_add_path --path --move "$HOME/.nix-profile/bin" \
      "/etc/profiles/per-user/$USER/bin" /run/current-system/sw/bin
  '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
