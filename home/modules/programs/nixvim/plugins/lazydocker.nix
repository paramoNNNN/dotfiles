{ pkgs, ... }: {
  programs.nixvim = {
    plugins.which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>f";
          group = "Telescope";
        }
        {
          __unkeyed-1 = "<leader>fd";
          __unkeyed-2 = "<Cmd>lua LazyDocker.toggle()<CR>";
          desc = "LazyDocker";
        }
      ];
      mode = [ "n" ];
    }];

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "lazydocker";
        src = pkgs.fetchFromGitHub {
          "owner" = "crnvl96";
          "repo" = "lazydocker.nvim";
          "rev" = "1e4d73a375057edb9a8e2c74b0fed9e311ed77ed";
          "hash" = "sha256-MLZeZuOPPbGfpTNqUTXUnMSXhmFihC+HWzgaonjXrqQ=";
        };
      })
    ];

    extraConfigLuaPost = ''
      require('lazydocker').setup({
        window = {
          settings = {
            width = 0.8,
            height = 0.8,
            border = rounded,
          }
        }
      });
    '';
  };
}
