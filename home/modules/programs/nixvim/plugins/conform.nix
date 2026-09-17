{ pkgs, ... }:
{
  programs.nixvim.extraPackagesAfter = [ pkgs.oxfmt ];

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
        json = [
          "oxfmt"
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        javascript = [
          "oxfmt"
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        typescript = [
          "oxfmt"
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        typescriptreact = [
          "oxfmt"
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        javascriptreact = [
          "oxfmt"
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        fish = [ "fish_indent" ];
        sh = [ "shfmt" ];
        css = [
          "oxfmt"
          "biome"
        ];
        vue = [
          "oxfmt"
          "prettierd"
          "prettier"
        ];
        astro = [
          "oxfmt"
          "prettierd"
          "prettier"
        ];
      };
      formatters = {
        oxfmt = {
          require_cwd = true;
        };
        biome = {
          command = "biome";
          args = [
            "check"
            "$FILENAME"
            "--write"
          ];
          stdin = false;
        };
      };
      format_on_save = {
        timeout_ms = 2000;
        lsp_format = "fallback";
        stop_after_first = true;
      };
    };
  };
}
