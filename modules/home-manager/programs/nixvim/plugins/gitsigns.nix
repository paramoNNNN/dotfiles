{
  programs.nixvim = {
    plugins.gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
        current_line_blame_formatter =
          "<author> • <author_time:%Y-%m-%d> • <summary>";
        signcolumn = true;
        numhl = true;
        on_attach = ''
          function()
            local gs = package.loaded.gitsigns
            local wk = require("which-key")

            wk.add({
              { "<leader>g", group = "Git" },
              {
                "<leader>g[",
                function()
                  if vim.wo.diff then
                    return "[c"
                  end
                  vim.schedule(function()
                    gs.prev_hunk()
                  end)
                  return "<Ignore>"
                end,
                desc = "Previous hunk",
              },
              {
                "<leader>g]",
                function()
                  if vim.wo.diff then
                    return "]c"
                  end
                  vim.schedule(function()
                    gs.next_hunk()
                  end)
                  return "<Ignore>"
                end,
                desc = "Next hunk",
              },
              {
                "<leader>gb",
                function()
                  gs.blame_line({ full = true })
                end,
                desc = "Blame line",
              },
              { "<leader>gd", gs.diffthis, desc = "Diff this" },
              { "<leader>gh", "<Cmd> Telescope git_signs<CR>", desc = "Preview hunks" },
              { "<leader>gi", gs.preview_hunk_inline, desc = "Preview hunk inline" },
              { "<leader>gr", gs.reset_hunk, desc = "Reset hunk" },
              { "<leader>gs", "<Cmd>Telescope git_status<CR>", desc = "Status" },
              { "<leader>gv", gs.preview_hunk, desc = "Preview hunk" },
            })
          end
        '';
      };
    };
  };
}
