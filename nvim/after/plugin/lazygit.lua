local wk = require("which-key")
wk.register({
  ["<leader>g"] = {
    name = "Git",
    g = { vim.cmd.LazyGit, "Open LazyGit" },
  },
})
