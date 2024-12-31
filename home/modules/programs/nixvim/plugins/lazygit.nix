{
  programs.nixvim.plugins = {
    which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
        }
        {
          __unkeyed-1 = "<leader>gg";
          __unkeyed-2 = "<Cmd>LazyGit<CR>";
          desc = "Open LazyGit";
        }
      ];
      mode = [ "n" ];
    }];
    lazygit = { enable = true; };
  };
}
