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
      settings = {
        filesystem = {
          follow_current_file = { enabled = true; };
          filtered-items = {
            hide_dot_files = false;
            hide_gitignored = false;
          };
        };
        close_if_last_window = true;
        window = { position = "right"; };
      };
    };
  };
}
