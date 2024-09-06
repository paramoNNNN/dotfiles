require("todo-comments").setup()

local wk = require("which-key")
wk.add({
  { "<leader>t", group = "Todo" },
  { "<leader>tl", "<Cmd>TodoTelescope<CR>", desc = "Telescope" },
  { "<leader>tq", "<Cmd>TodoQuickFix<CR>", desc = "QuickFix" },
})
