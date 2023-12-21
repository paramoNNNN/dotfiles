require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
    json = { { "eslint_d", "prettierd", "prettier" } },
    javascript = { { "eslint_d", "prettierd", "prettier" } },
    typescript = { { "eslint_d", "prettierd", "prettier" } },
    typescriptreact = { { "eslint_d", "prettierd", "prettier" } },
    javascriptreact = { { "eslint_d", "prettierd", "prettier" } },
    fish = { { "fish_ident" } },
    sh = { { "shfmt" } },
  },
  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = true,
  },
})
