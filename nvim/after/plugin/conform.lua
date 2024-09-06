require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
    json = { "biome-check", "prettierd", "prettier", "eslint_d" },
    javascript = { "biome-check", "prettierd", "prettier", "eslint_d" },
    typescript = { "biome-check", "prettierd", "prettier", "eslint_d" },
    typescriptreact = { "biome-check", "prettierd", "prettier", "eslint_d" },
    javascriptreact = { "biome-check", "prettierd", "prettier", "eslint_d" },
    fish = { "fish_ident" },
    sh = { "shfmt" },
    css = { "biome-check" },
  },
  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = true,
    stop_after_first = true,
  },
})
