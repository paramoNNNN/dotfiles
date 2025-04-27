{ pkgs, ... }: {

  programs.nixvim.plugins.which-key.settings.spec = [{
    __unkeyed-1 = [
      {
        __unkeyed-1 = "<leader>n";
        __unkeyed-2 =
          {
            __raw = ''
              function() require("multicursor-nvim").matchAddCursor(1) end
            '';
          };
        desc = "Add a cursor by matching selection";
      }
      {
        __unkeyed-1 = "<leader>b";
        __unkeyed-2 =
          {
            __raw = ''
              function() require("multicursor-nvim").matchSkipCursor(1) end
            '';
          };
        desc = "Skip a cursor by matching selection";
      }
    ];
    mode = [ "x" ];
  }];

  programs.nixvim.extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "multicursor";
      src = pkgs.fetchFromGitHub {
        "owner" = "jake-stewart";
        "repo" = "multicursor.nvim";
        "rev" = "0ca2ccdec1f10430940f751a2044a0955777f174";
        "hash" = "sha256-NcQszrisuVlcKkSOELD475NkaGFIx+m2ndBLQFMxhfI=";
      };

    })
  ];

  programs.nixvim.extraConfigLuaPost = ''
    local mc = require("multicursor-nvim")
    mc.setup()

    mc.addKeymapLayer(function(layerSet)
       layerSet("n", "<esc>", function()
           if not mc.cursorsEnabled() then
               mc.enableCursors()
           else
               mc.clearCursors()
           end
       end)
    end)
  '';

}
