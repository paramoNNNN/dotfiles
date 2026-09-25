{ lib, ... }:
let
  syncOnActivation = false;
in
{
  system.activationScripts.homebrew.text = lib.mkIf (!syncOnActivation) (
    lib.mkForce ''
      echo "Homebrew sync skipped (syncOnActivation = false in hosts/taha-mac/homebrew.nix)."
    ''
  );
  homebrew = {
    enable = true;
    global.brewfile = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # keep existing packages while the migration is incomplete.
      cleanup = "none";
    };
    taps = [
      "cormacrelf/tap"
      "homebrew/bundle"
      "homebrew/services"
      "isacikgoz/taps"
      "jesseduffield/lazydocker"
      "mongodb/brew"
      "ngrok/ngrok"
      "nikitabobko/tap"
      "oven-sh/bun"
    ];
    brews = [
      "mole"
    ];
    casks = [
      "aerospace"
      "aldente"
      "android-platform-tools"
      "atomic-wallet"
      "battery-buddy"
      "bitwarden"
      "blender"
      "brave-browser"
      "cleanshot"
      "coconutbattery"
      "discord"
      "dozer"
      "figma"
      "firefox@developer-edition"
      "flacon"
      "flux-app"
      "ghostty"
      "handbrake-app"
      "hoppscotch"
      "iina"
      "kitty"
      "macs-fan-control"
      "mattermost"
      "moonlight"
      "mounty"
      "musicbrainz-picard"
      "orbstack"
      "pgadmin4"
      "plexamp"
      "proton-mail"
      "raycast"
      "retrobatch"
      "steam"
      "teamspeak-client"
      "telegram"
      "the-unarchiver"
      "tunnelblick"
      "ungoogled-chromium"
      "sfm"
    ];
  };
}
