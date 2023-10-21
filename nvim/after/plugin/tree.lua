require("neo-tree").setup({
	window = {
		position = "right",
	},
})

local wk = require("which-key")
wk.register({
	["<leader>d"] = {
		name = "Neotree",
		t = { "<Cmd>Neotree toggle<CR>", "Toggle" },
	},
})
