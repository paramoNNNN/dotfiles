{ lib, pkgs, ... }: {
  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    settings = {
      formatters_by_ft = {
        lua = [ "stylua" ];
        nix = [ "nixfmt" ];
        python = [ "isort" "black" ];
        json = [ "biome-check" "prettierd" "prettier" "eslint_d" ];
        javascript = [ "biome-check" "prettierd" "prettier" "eslint_d" ];
        typescript = [ "biome-check" "prettierd" "prettier" "eslint_d" ];
        typescriptreact = [ "biome-check" "prettierd" "prettier" "eslint_d" ];
        javascriptreact = [ "biome-check" "prettierd" "prettier" "eslint_d" ];
        fish = [ "fish_indent" ];
        sh = [ "shfmt" ];
        css = [ "biome-check" ];
        vue = [ "prettierd" "prettier" ];
        astro = [ "prettierd" "prettier" ];
      };
      format_on_save = {
        timeout_ms = 2000;
        lsp_fallback = true;
        stop_after_first = true;
      };
      formatters = { biome-check = { command = lib.getExe pkgs.biome; }; };
    };
  };
}
