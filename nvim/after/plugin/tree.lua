require("neo-tree").setup({
	filesystem = {
		filtered_items = {
			hide_dotfiles = false,
		},
		follow_current_file = {
			enabled = true,
		},
	},
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
