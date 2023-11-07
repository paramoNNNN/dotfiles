local wk = require("which-key")
wk.register({
  ["<leader>g"] = {
    name = "LazyGit",
    g = { vim.cmd.LazyGit, "Show" },
  },
})
