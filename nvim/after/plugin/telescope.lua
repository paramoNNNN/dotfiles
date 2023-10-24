local telescope = require("telescope")
local telescopeConfig = require("telescope.config")
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

-- TODO: this is deprected, find an alternative
local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

table.insert(vimgrep_arguments, "--hidden")
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")

telescope.setup({
	defaults = {
		vimgrep_arguments = vimgrep_arguments,
	},
	pickers = {
		find_files = {
			find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
		},
	},
})
