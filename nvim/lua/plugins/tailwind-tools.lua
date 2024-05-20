return {
  "luckasRanarison/tailwind-tools.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    document_color = {
      kind = "background",
    },
  },
  init = function()
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
      pattern = "*.tsx",
      command = "TailwindSort",
    })
  end,
}
