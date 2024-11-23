local notify = require("notify")
notify.setup({ render = "compact", stages = "fade" })
vim.notify = notify

local wk = require("which-key")
wk.add({
  { "<leader><S-C>", "<Cmd>lua require('notify').dismiss()<CR>", desc = "Dismiss notifications" },
})
