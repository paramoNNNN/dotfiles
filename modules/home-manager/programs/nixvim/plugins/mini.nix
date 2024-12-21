{
  programs.nixvim.plugins.mini = {
    enable = true;
    modules = {
      cursorword = { };
      pairs = { };
      comment = { };
      surround = { };
    };
  };
}

