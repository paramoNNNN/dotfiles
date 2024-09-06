local wk = require("which-key")
wk.add({
  { "<leader>q", group = "Persistence" },
  { "<leader>ql", '<cmd>lua require("persistence").load({ last = true })<cr>', desc = "Load last session" },
  { "<leader>qs", '<cmd>lua require("persistence").load()<cr>', desc = "Restore session for current directory" },
})
