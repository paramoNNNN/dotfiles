require("gitsigns").setup({
  current_line_blame = true,
  current_line_blame_formatter = "<author> • <author_time:%Y-%m-%d> • <summary>",
  signcolumn = true,
  numhl = true,
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    -- TODO: use which-key to register this keymaps
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map("n", "]c", function()
      if vim.wo.diff then
        return "]c"
      end
      vim.schedule(function()
        gs.next_hunk()
      end)
      return "<Ignore>"
    end, { expr = true })

    map("n", "[c", function()
      if vim.wo.diff then
        return "[c"
      end
      vim.schedule(function()
        gs.prev_hunk()
      end)
      return "<Ignore>"
    end, { expr = true })

    map("n", "<leader>hp", gs.preview_hunk)
    map("n", "<leader>hb", function()
      gs.blame_line({ full = true })
    end)
  end,
})
