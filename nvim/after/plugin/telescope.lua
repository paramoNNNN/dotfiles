local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.load_extension("projects")
telescope.load_extension("file_browser")

local wk = require("which-key")
wk.register({
	["<leader>f"] = {
		name = "Telescope",
		f = { builtin.find_files, "Find files" },
		g = { builtin.live_grep, "Live grep" },
		b = { builtin.buffer, "Buffers" },
		h = { builtin.help_tags, "Help tags" },
	},
})
