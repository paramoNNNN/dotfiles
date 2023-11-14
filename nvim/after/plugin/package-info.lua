require("package-info").setup()

local wk = require("which-key")
wk.register({
  ["<leader>n"] = {
    name = "Package Info",
    s = {
      "<cmd>lua require('package-info').show({ force = true })<cr>",
      "Display latest package version",
      { silent = true, noremap = true },
    },
    d = {
      "<cmd>lua require('package-info').delete()<cr>",
      "Delete dependency",
      { silent = true, noremap = true },
    },
    c = {
      "<cmd>lua require('package-info').change_version()<cr>",
      "Install different version",
      { silent = true, noremap = true },
    },
    i = {
      "<cmd>lua require('package-info').install()<cr>",
      "Install new dependency",
      { silent = true, noremap = true },
    },
  },
})
