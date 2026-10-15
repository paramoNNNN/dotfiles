{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.textamp.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  nix.settings = {
    extra-substituters = [ "https://terminal-music-player.cachix.org" ];
    extra-trusted-public-keys = [
      "terminal-music-player.cachix.org-1:3lKj0+0+0WnRLNi9QXalpYPnS8BVJK1lSgfOeQJW6+k="
    ];
  };
}
