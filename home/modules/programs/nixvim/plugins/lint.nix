{ pkgs, ... }:
{
  # Run standalone diagnostics on save, without a second LSP/formatting bridge.
  programs.nixvim = {
    extraPackagesAfter = with pkgs; [
      deadnix
      pylint
      checkstyle
    ];
    plugins.lint = {
      enable = true;
      lintersByFt = {
        nix = [ "deadnix" ];
        python = [ "pylint" ];
        java = [ "checkstyle" ];
      };
      autoCmd.event = "BufWritePost";
    };
  };
}
