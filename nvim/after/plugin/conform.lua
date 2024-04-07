require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
    json = { { "prettierd", "prettier", "eslint_d" } },
    javascript = { { "prettierd", "prettier", "eslint_d" } },
    typescript = { { "prettierd", "prettier", "eslint_d" } },
    typescriptreact = { { "prettierd", "prettier", "eslint_d" } },
    javascriptreact = { { "prettierd", "prettier", "eslint_d" } },
    fish = { { "fish_ident" } },
    sh = { { "shfmt" } },
  },
  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = true,
  },
})
