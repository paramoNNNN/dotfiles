require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		-- Conform will run multiple formatters sequentially
		python = { "isort", "black" },
		-- Use a sub-list to run only the first available formatter
		javascript = { { "eslint_d", "prettierd", "prettier" } },
		typescript = { { "eslint_d", "prettierd", "prettier" } },
		typescriptreact = { { "eslint_d", "prettierd", "prettier" } },
		javascriptreact = { { "eslint_d", "prettierd", "prettier" } },
	},
	format_on_save = {
		-- These options will be passed to conform.format()
		timeout_ms = 500,
		lsp_fallback = true,
	},
})
