{
  programs.nixvim.plugins = {
    which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>p";
          group = "Package info";
        }
        {
          __unkeyed-1 = "<leader>ps";
          __unkeyed-2 =
            "<Cmd>lua require('package-info').show({ force = true })<CR>";
          desc = "Display latest package version";
        }
        {
          __unkeyed-1 = "<leader>pd";
          __unkeyed-2 = "<Cmd>lua require('package-info').delete()<CR>";
          desc = "Delete dependency";
        }
        {
          __unkeyed-1 = "<leader>pc";
          __unkeyed-2 = "<Cmd>lua require('package-info').change_version()<CR>";
          desc = "Install different version";
        }
        {
          __unkeyed-1 = "<leader>pi";
          __unkeyed-2 = "<Cmd>lua require('package-info').install()<CR>";
          desc = "Install new dependency";
        }
      ];
      mode = [ "n" ];
    }];

    package-info = { enable = true; };
  };
}
