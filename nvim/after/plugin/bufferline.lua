local bufferline = require("bufferline")
bufferline.setup({
	options = {
		mode = "buffers",
		style_preset = bufferline.style_preset.default,
		buffer_close_icon = "",
		tab_size = 20,
		diagnostics = "nvim_lsp",
	},
})

local wk = require("which-key")
wk.register({
	["<leader>"] = {
		["1"] = { "<cmd>lua require('bufferline').go_to_buffer(1, true)<cr>", "Go to buffer 1" },
		["2"] = { "<cmd>lua require('bufferline').go_to_buffer(2, true)<cr>", "Go to buffer 2" },
		["3"] = { "<cmd>lua require('bufferline').go_to_buffer(3, true)<cr>", "Go to buffer 3" },
		["4"] = { "<cmd>lua require('bufferline').go_to_buffer(4, true)<cr>", "Go to buffer 4" },
		["5"] = { "<cmd>lua require('bufferline').go_to_buffer(5, true)<cr>", "Go to buffer 5" },
		["6"] = { "<cmd>lua require('bufferline').go_to_buffer(6, true)<cr>", "Go to buffer 6" },
		["7"] = { "<cmd>lua require('bufferline').go_to_buffer(7, true)<cr>", "Go to buffer 7" },
		["8"] = { "<cmd>lua require('bufferline').go_to_buffer(8, true)<cr>", "Go to buffer 8" },
		["9"] = { "<cmd>lua require('bufferline').go_to_buffer(9, true)<cr>", "Go to buffer 9" },
	},
	["<leader>b"] = {
		name = "Bufferline",
		d = { vim.cmd.bdelete, "Close current buffer" },
	},
})
