{ pkgs, ... }: {
  programs.nixvim = {
    plugins.which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>t";
          group = "Tailwind tools";
        }
        {
          __unkeyed-1 = "<leader>ts";
          __unkeyed-2 = "<Cmd>TailwindSortSelection<CR>";
          desc = "Sort selection";
        }
      ];
      mode = [ "v" ];
    }
      {
        __unkeyed-1 = [
          {
            __unkeyed-1 = "<leader>t";
            group = "Tailwind tools";
          }
          {
            __unkeyed-1 = "<leader>ts";
            __unkeyed-2 = "<Cmd>TailwindSort<CR>";
            desc = "Sort file";
          }
        ];
        mode = [ "n" ];
      }];

    extraPlugins = with pkgs.vimPlugins; [ tailwind-tools-nvim ];

    autoCmd = [{
      command = "TailwindSort";
      event = "BufWritePre";
      pattern = "*.tsx";
    }];

    extraConfigLuaPost = ''
      require("tailwind-tools").setup({});
    '';
  };
}
