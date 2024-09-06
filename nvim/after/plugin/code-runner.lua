require("code_runner").setup({
  mode = "float",
  filetype = {
    javascript = "bun",
    typescript = "bun",
    typescriptreact = "bun",
  },
})

local wk = require("which-key")
wk.add({
  { "<leader>r", group = "Code Runner" },
  { "<leader>rc", "<Cmd>RunClose<CR>", desc = "Close runner" },
  { "<leader>rr", "<Cmd>RunFile<CR>", desc = "Run File" },
})
