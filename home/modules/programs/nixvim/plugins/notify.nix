{
  programs.nixvim.plugins = {
    which-key.settings.spec = [{
      __unkeyed-1 = [{
        __unkeyed-1 = "<leader><S-C>";
        __unkeyed-2 = "<Cmd>lua require('notify').dismiss()<CR>";
        desc = "Dismiss notifications";
      }];
      mode = [ "n" ];
    }];

    notify = {
      enable = true;
      settings = {
        background_colour = "#000000";
        render = "compact";
        stages = "fade";
      };
    };
  };
}
