{

  programs.nixvim.plugins.lualine = {
    enable = true;
    settings = {
      options = {
        theme = "catppuccin";
        globalstatus = true;
      };
      sections = {
        lualine_b = [ "diagnostics" ];
        lualine_c = [{
          __unkeyed-1 = "filename";
          path = 4;
        }];
        lualine_x = [ "filetype" ];
      };
    };
  };
}
