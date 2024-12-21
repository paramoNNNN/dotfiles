{
  programs.nixvim.plugins.toggleterm = {
    enable = true;
    settings = {
      open_mapping = "[[<c-\\>]]";
      direction = "float";
      shade_terminals = true;
      float_opts = { border = "curved"; };
    };
  };
}
