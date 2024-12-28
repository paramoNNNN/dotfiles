{
  programs.nixvim.plugins.none-ls = {
    enable = true;
    settings = {
      cmd = [ "bash -c nvim" ];
      debug = true;
    };
    sources = {
      code_actions = {
        statix.enable = true;
        gitsigns.enable = true;
      };
      diagnostics = {
        statix.enable = true;
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
      completion = {
        luasnip.enable = true;
        spell.enable = true;
      };
    };
  };
}
