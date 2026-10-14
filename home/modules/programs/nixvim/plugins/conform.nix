{ pkgs, ... }:
let
  web = {
    __unkeyed-1 = "oxfmt";
    __unkeyed-2 = "biome";
    __unkeyed-3 = "prettier";
    stop_after_first = true;
  };
in
{
  programs.nixvim.extraPackagesAfter = with pkgs; [
    oxfmt
    stylua
    shfmt
    nixfmt
    prettier
    isort
    black
  ];

  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    settings = {
      formatters_by_ft = {
        lua = [ "stylua" ];
        nix = [ "nixfmt" ];
        python = [
          "isort"
          "black"
        ];
        json = web;
        jsonc = web;
        javascript = web;
        typescript = web;
        typescriptreact = web;
        javascriptreact = web;
        css = web;
        scss = [ "prettier" ];
        html = [ "prettier" ];
        yaml = [ "prettier" ];
        markdown = [ "prettier" ];
        fish = [ "fish_indent" ];
        sh = [ "shfmt" ];
        vue = [ "prettier" ];
        astro.__raw = ''
          function(bufnr)
            local filename = vim.api.nvim_buf_get_name(bufnr)
            if vim.fs.root(filename, { "node_modules/prettier-plugin-astro" }) then
              return { "prettier" }
            end
            return {}
          end
        '';
      };
      formatters = {
        oxfmt.require_cwd = true;
        biome.require_cwd = true;
      };
      default_format_opts.lsp_format = "fallback";
      format_on_save = {
        timeout_ms = 2000;
        lsp_format = "fallback";
      };
    };
  };
}
