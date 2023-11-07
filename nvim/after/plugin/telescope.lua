local telescope = require("telescope")
local telescopeConfig = require("telescope.config")
local builtin = require("telescope.builtin")

telescope.load_extension("projects")
telescope.load_extension("file_browser")
telescope.load_extension("live_grep_args")

local wk = require("which-key")
wk.register({
  ["<leader>f"] = {
    name = "Telescope",
    f = { builtin.find_files, "Find files" },
    g = { builtin.live_grep, "Live grep" },
    l = { telescope.extensions.live_grep_args.live_grep_args, "Live grep args" },
    q = { builtin.quickfix, "Quickfix" },
    h = { builtin.help_tags, "Help tags" },
  },
  ["<leader><leader>"] = { builtin.buffers, "Buffers" },
})

-- TODO: this is deprected, find an alternative
local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

table.insert(vimgrep_arguments, "--hidden")
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")

local actions = require("telescope.actions")

local function send_to_quickfix_and_open(promtbufnr)
  actions.smart_send_to_qflist(promtbufnr)
  builtin.quickfix()
end

telescope.setup({
  defaults = {
    vimgrep_arguments = vimgrep_arguments,
    mappings = {
      n = {
        ["<C-q>"] = send_to_quickfix_and_open,
      },
      i = {
        ["<C-d>"] = actions.delete_buffer,
        ["<C-q>"] = send_to_quickfix_and_open,
      },
    },
  },
  pickers = {
    find_files = {
      find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
    },
    buffers = {
      sort_lastused = true,
      sort_mru = true,
    },
  },
})
