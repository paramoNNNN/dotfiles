{
  programs.nixvim.plugins = {

    which-key.settings.spec = [{
      __unkeyed-1 = [{
        __unkeyed-1 = "<leader>u";
        __unkeyed-2 = "<Cmd>UndotreeToggle<CR>";
        group = "Undotree";
      }];
      mode = [ "n" ];
    }];

    undotree = { enable = true; };
  };
}
