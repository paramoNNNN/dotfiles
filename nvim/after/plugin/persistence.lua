local wk = require("which-key")
wk.register({
	["<leader>q"] = {
		name = "Persistence",
		s = { [[<cmd>lua require("persistence").load()<cr>]], "Restore session for current directory" },
		l = { [[<cmd>lua require("persistence").load({ last = true })<cr>]], "Load last session" },
	},
})
