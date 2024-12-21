{
  programs.nixvim = {
    plugins.which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>d";
          group = "Neotree";
        }
        {
          __unkeyed-1 = "<leader>dt";
          __unkeyed-2 = "<Cmd>Neotree toggle<CR>";
          desc = "Toggle";
        }
      ];
      mode = [ "n" ];
    }];

    plugins.neo-tree = {
      enable = true;
      filesystem = {
        followCurrentFile = { enabled = true; };
        filteredItems = {
          hideDotfiles = false;
          hideGitignored = false;
        };
      };
      closeIfLastWindow = true;
      window = { position = "right"; };
    };
  };
}
