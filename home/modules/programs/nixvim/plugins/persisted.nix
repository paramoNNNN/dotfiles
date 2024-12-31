{
  programs.nixvim.plugins = {
    which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>q";
          group = "Sessions";
        }
        {
          __unkeyed-1 = "<leader>ql";
          __unkeyed-2 = "<Cmd>SessionLoadLast<CR>";
          desc = "Load last session";
        }
        {
          __unkeyed-1 = "<leader>qs";
          __unkeyed-2 = "<Cmd>SessionLoad<CR>";
          desc = "Restore session for current directory";
        }
      ];
      mode = [ "n" ];
    }];

    persisted = {
      enable = true;
      enableTelescope = true;
      settings = { use_git_branch = true; };
    };
  };
}
