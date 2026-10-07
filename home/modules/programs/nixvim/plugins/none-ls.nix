{
  programs.nixvim.plugins.none-ls = {
    enable = true;
    settings = {
      debug = false;
    };
    sources = {
      code_actions = {
        gitsigns.enable = true;
      };
      diagnostics = {
        deadnix.enable = true;
        pylint.enable = true;
        checkstyle.enable = true;
      };
      formatting = {
        black = {
          enable = true;
          settings = ''
            {
              extra_args = { "--fast" },
            }
          '';
        };
      };
    };
  };
}
