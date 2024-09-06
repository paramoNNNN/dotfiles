local wk = require("which-key")
wk.add({
  { "<leader>g", group = "Git" },
  { "<leader>gg", vim.cmd.LazyGit, desc = "Open LazyGit" },
})
