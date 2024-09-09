local gitpad = require("gitpad")
local wk = require("which-key")

wk.add({
  { "<leader>n", group = "Notes" },
  {
    "<leader>np",
    function()
      gitpad.toggle_gitpad({ title = "Project notes" })
    end,
    desc = "Project notes",
  },
  {
    "<leader>nb",
    function()
      gitpad.toggle_gitpad_branch({ title = "Branch notes" })
    end,
    desc = "Branch notes",
  },
  {
    "<leader>nB",
    function()
      gitpad.toggle_gitpad_branch({ window_type = "split", split_win_opts = { split = "right" } })
    end,
    desc = "Branch vertical split notes",
  },
  {
    "<leader>nd",
    function()
      local date_filename = "daily-" .. os.date("%Y-%m-%d.md")
      gitpad.toggle_gitpad({ filename = date_filename, title = "Daily notes" })
    end,
    desc = "Daily notes",
  },
  {
    "<leader>nf",
    function()
      local filename = vim.fn.expand("%:p") -- or just use vim.fn.bufname()
      if filename == "" then
        vim.notify("empty bufname")
        return
      end
      filename = vim.fn.pathshorten(filename, 2) .. ".md"
      require("gitpad").toggle_gitpad({ filename = filename, title = "Current file notes" })
    end,
    desc = "Per file notes",
  },
})
