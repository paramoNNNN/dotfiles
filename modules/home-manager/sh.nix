{ lib, ... }:

{
  programs.bash = { enable = true; };

  programs.fish = { enable = true; };

  programs.alacritty = {
    enable = true;
    settings = lib.attrsets.recursiveUpdate (import ./programs/alacritty.nix) {
      shell.program = "fish";
    };
  };

  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      default_shell = "fish";
      simplified_ui = true;
    };
  };
}
