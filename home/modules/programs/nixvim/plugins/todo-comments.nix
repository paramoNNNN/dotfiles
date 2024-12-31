{
  programs.nixvim.plugins = {
    which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>t";
          group = "Todo";
        }
        {
          __unkeyed-1 = "<leader>tl";
          __unkeyed-2 = "<Cmd>TodoTelescope<CR>";
          desc = "View TODOs in Telescope";
        }
        {
          __unkeyed-1 = "<leader>tq";
          __unkeyed-2 = "<Cmd>TodoQuickFix<CR>";
          desc = "Quickfix";
        }
      ];
      mode = [ "n" ];
    }];
    todo-comments = { enable = true; };
  };
}
