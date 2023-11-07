require("todo-comments").setup()

local wk = require("which-key")
wk.register({
  ["<leader>t"] = {
    name = "Todo",
    q = { "<Cmd>TodoQuickFix<CR>", "QuickFix" },
    l = { "<Cmd>TodoTelescope<CR>", "Telescope" },
  },
})
