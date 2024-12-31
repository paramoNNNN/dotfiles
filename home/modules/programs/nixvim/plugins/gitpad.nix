{ pkgs, ... }: {
  programs.nixvim = {
    plugins.which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>n";
          group = "Notes";
        }
        {
          __unkeyed-1 = "<leader>np";
          __unkeyed-2 = {
            __raw = ''
              function()
                require("gitpad").toggle_gitpad({ title = "Project notes" })
              end
            '';
          };
          desc = "Project notes";
        }
        {
          __unkeyed-1 = "<leader>nb";
          __unkeyed-2 = {
            __raw = ''
              function()
                require("gitpad").toggle_gitpad_branch({ title = "Branch notes" })
              end
            '';
          };
          desc = "Branch notes";
        }
        {
          __unkeyed-1 = "<leader>nB";
          __unkeyed-2 = {
            __raw = ''
              function()
                require("gitpad").toggle_gitpad_branch({ window_type = "split", split_win_opts = { split = "right" } })
              end
            '';
          };
          desc = "Branch notes (vertical split)";
        }
      ];
      mode = [ "n" ];
    }];

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "gitpad";
        src = pkgs.fetchFromGitHub {
          owner = "yujinyuz";
          repo = "gitpad.nvim";
          rev = "1e0f6fa335c72c05d1d3635120c572e198e5ae0d";
          hash = "sha256-mtSb7bpa//kr9DKsABK57J8NpS3TgLiv4ASru0ztCQ0=";
        };
      })
    ];

    extraConfigLuaPost = ''
      require('gitpad').setup({
        floating_win_opts = {
          border = 'rounded',
        }, 
      });
    '';
  };

}
