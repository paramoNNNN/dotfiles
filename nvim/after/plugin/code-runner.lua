require("code_runner").setup({
  mode = "float",
  filetype = {
    javascript = "bun",
    typescript = "bun",
    typescriptreact = "bun",
  },
})

local wk = require("which-key")
wk.register({
  ["<leader>r"] = {
    "Code Runner",
    c = { "<Cmd>RunClose<CR>", "Close runner" },
    r = { "<Cmd>RunFile<CR>", "Run File" },
  },
})
