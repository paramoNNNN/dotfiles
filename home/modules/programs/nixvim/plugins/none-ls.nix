{
  programs.nixvim.plugins.none-ls = {
    enable = true;
    settings = {
      cmd = [ "bash -c nvim" ];
      debug = true;
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
        stylua.enable = true;
        shfmt.enable = true;
        nixpkgs_fmt.enable = true;
        prettier = {
          enable = true;
          disableTsServerFormatter = true;
        };
        black = {
          enable = true;
          settings = ''
            {
              extra_args = { "--fast" },
            }
          '';
        };
        biome = { enable = true; };
      };
    };
  };
}
