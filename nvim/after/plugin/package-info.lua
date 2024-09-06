require("package-info").setup()

local wk = require("which-key")
wk.add({
  { "<leader>n", group = "Package Info" },
  {
    "<leader>ns",
    "<cmd>lua require('package-info').show({ force = true })<cr>",
    desc = "Display latest package version",
  },
  {
    "<leader>nd",
    "<cmd>lua require('package-info').delete()<cr>",
    desc = "Delete dependency",
  },
  {
    "<leader>nc",
    "<cmd>lua require('package-info').change_version()<cr>",
    desc = "Install different version",
  },
  {
    "<leader>ni",
    "<cmd>lua require('package-info').install()<cr>",
    desc = "Install new dependency",
  },
})
