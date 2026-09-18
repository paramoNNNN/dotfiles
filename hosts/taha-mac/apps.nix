{ pkgs, ... }:
{
  # Keep existing app installations until the Nix copies pass launch checks.
  environment.systemPackages = with pkgs; [
    aerospace
    android-tools
    bitwarden-desktop
    blender
    brave
    discord
    firefox-devedition
    iina
    kitty
    moonlight-qt
    picard
    pgadmin4
    protonmail-desktop
    raycast
    steam
    telegram-desktop
  ];
}
