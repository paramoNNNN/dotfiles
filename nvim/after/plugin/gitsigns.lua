require("gitsigns").setup({
  current_line_blame = true,
  current_line_blame_formatter = "<author> • <author_time:%Y-%m-%d> • <summary>",
  signcolumn = true,
  numhl = true,
  on_attach = function()
    local gs = package.loaded.gitsigns
    local wk = require("which-key")

    wk.register({
      ["<leader>g"] = {
        name = "Git",
        ["]"] = {
          function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end,
          "Next hunk",
          { expr = true },
        },
        ["["] = {
          function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end,
          "Previous hunk",
          { expr = true },
        },
        ["v"] = {
          gs.preview_hunk,
          "Preview hunk",
        },
        ["i"] = {
          gs.preview_hunk_inline,
          "Preview hunk inline",
          { expr = true },
        },
        ["b"] = {
          function()
            gs.blame_line({ full = true })
          end,
          "Blame line",
        },
        ["d"] = {
          gs.diffthis,
          "Diff this",
          { expr = true },
        },
      },
    })
  end,
})
