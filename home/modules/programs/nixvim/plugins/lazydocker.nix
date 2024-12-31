{ pkgs, ... }: {
  programs.nixvim = {
  #   plugins.which-key.settings.spec = [{
  #     __unkeyed-1 = [
  #       {
  #         __unkeyed-1 = "<leader>f";
  #         group = "Telescope";
  #       }
  #       {
  #         __unkeyed-1 = "<leader>fd";
  #         __unkeyed-2 = "<Cmd>LazyDocker<CR>";
  #         desc = "LazyDocker";
  #       }
  #     ];
  #     mode = [ "n" ];
  #   }];
  #
  #   extraPlugins = [
  #     (pkgs.vimUtils.buildVimPlugin {
  #       name = "lazydocker";
  #       src = pkgs.fetchFromGitHub {
  #         "owner" = "crnvl96";
  #         "repo" = "lazydocker.nvim";
  #         "rev" = "6f59d4d4993db834d0e0cada9e4f8d945374812e";
  #         "hash" = "sha256-u8BFawmXiSd5hoBUglfQZdTuIqArOhk6J4+NypF4UKM=";
  #       };
  #     })
  #   ];
  #
  #   extraConfigLuaPost = ''
  #     require('lazydocker').setup();
  #   '';
  };
}
