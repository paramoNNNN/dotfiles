{ config, lib, ... }:
{
  programs.nixvim.plugins.toggleterm = {
    enable = true;
    settings = {
      shell = lib.getExe config.programs.fish.package;
      open_mapping = "[[<c-\\>]]";
      direction = "float";
      shade_terminals = true;
      float_opts = {
        border = "curved";
      };
    };
  };
}
