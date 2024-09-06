local telescope = require("telescope")
local telescopeConfig = require("telescope.config")
local builtin = require("telescope.builtin")

telescope.load_extension("projects")
telescope.load_extension("file_browser")
telescope.load_extension("live_grep_args")
telescope.load_extension("git_signs")
telescope.load_extension("advanced_git_search")

local wk = require("which-key")
wk.add({
  { "<leader>f", group = "Telescope" },
  { "<leader>fa", "<Cmd>AdvancedGitSearch<CR>", desc = "Git search" },
  { "<leader>fb", telescope.extensions.file_browser.file_browser, desc = "File browser" },
  { "<leader>fd", vim.cmd.LazyDocker, desc = "LazyDocker" },
  { "<leader>ff", builtin.find_files, desc = "Find files" },
  { "<leader>fg", builtin.live_grep, desc = "Live grep" },
  { "<leader>fh", builtin.help_tags, desc = "Help tags" },
  { "<leader>fl", telescope.extensions.live_grep_args.live_grep_args, desc = "Live grep args" },
  { "<leader>fn", "<Cmd>Telescope notify<CR>", desc = "Notifications history" },
  { "<leader>fp", "<Cmd>Telescope projects<CR>", desc = "Projects" },
  { "<leader>fq", builtin.quickfix, desc = "Quickfix" },
  { "<leader><leader>", builtin.buffers, desc = "Buffers" },
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
