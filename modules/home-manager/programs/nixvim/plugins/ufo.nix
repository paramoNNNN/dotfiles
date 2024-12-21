{
  programs.nixvim.plugins = {
    which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "zR";
          __unkeyed-2 = "<Cmd>lua require('ufo').openAllFolds<CR>";
          desc = "Open all folds";
        }
        {
          __unkeyed-1 = "zM";
          __unkeyed-2 = "<Cmd>lua require('ufo').closeAllFolds<CR>";
          desc = "Close all folds";
        }
      ];
      mode = [ "n" ];
    }];

    nvim-ufo = { enable = true; };
  };
}
