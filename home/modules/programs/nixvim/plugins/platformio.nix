{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "platformio";
        src = pkgs.fetchFromGitHub {
          "owner" = "sbatin";
          "repo" = "platformio.nvim";
          "rev" = "546e1e0b5afdd970f140d0ccaf322d41c0f23941";
          "hash" = "sha256-PXsuhYmI3uLwjFZgSlliya2YlMWPRHTHKiUGSOJ6/ig=";
        };
      })
      (pkgs.vimUtils.buildVimPlugin {
        name = "fterm";
        src = pkgs.fetchFromGitHub {
          "owner" = "numToStr";
          "repo" = "FTerm.nvim";
          "rev" = "d1320892cc2ebab472935242d9d992a2c9570180";
          "hash" = "sha256-fCtAs6qsvWOYRp2Z1AwQa2ByUZcUCMKfuYBoNTP7EeY=";
        };
      })

    ];
  };
}
