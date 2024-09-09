require("package-info").setup()

local wk = require("which-key")
wk.add({
  { "<leader>p", group = "Package Info" },
  {
    "<leader>ps",
    "<cmd>lua require('package-info').show({ force = true })<cr>",
    desc = "Display latest package version",
  },
  {
    "<leader>pd",
    "<cmd>lua require('package-info').delete()<cr>",
    desc = "Delete dependency",
  },
  {
    "<leader>pc",
    "<cmd>lua require('package-info').change_version()<cr>",
    desc = "Install different version",
  },
  {
    "<leader>pi",
    "<cmd>lua require('package-info').install()<cr>",
    desc = "Install new dependency",
  },
})
