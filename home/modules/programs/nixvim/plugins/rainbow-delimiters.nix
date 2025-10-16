{
  programs.nixvim.plugins.rainbow-delimiters = {
    enable = true;
    settings = { query = { tsx = "rainbow-parens"; }; };
  };
}
