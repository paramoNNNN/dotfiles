{ ... }:
{
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
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        javascript = [
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        typescript = [
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        typescriptreact = [
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        javascriptreact = [
          "biome"
          "prettierd"
          "prettier"
          "eslint_d"
        ];
        fish = [ "fish_indent" ];
        sh = [ "shfmt" ];
        css = [ "biome" ];
        vue = [
          "prettierd"
          "prettier"
        ];
        astro = [
          "prettierd"
          "prettier"
        ];
      };
      formatters = {
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
