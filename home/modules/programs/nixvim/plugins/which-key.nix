{
  programs.nixvim.plugins.which-key = {
    enable = true;
    settings = {
      expand = 1;
      notify = false;
      preset = false;
      delay = 300;
      replace = { desc = [ [ "<space>" "SPACE" ] [ "<leader>" "SPACE" ] ]; };
    };
  };
}
