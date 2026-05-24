{
  programs.nixvim = {
    plugins = {
      which-key.settings.spec = [
        {
          __unkeyed-1 = [
            {
              __unkeyed-1 = "<leader>g";
              group = "Git";
            }
            {
              __unkeyed-1 = "<leader>gg";
              __unkeyed-2 = "<Cmd>LazyGit<CR>";
              desc = "Open LazyGit";
            }
          ];
          mode = [ "n" ];
        }
      ];

      lazygit = {
        enable = true;
      };
    };

    extraConfigLuaPost = ''
      function lazygitOpenFile(filename, line_number)
        line_number = tonumber(line_number) or 1

        vim.api.nvim_win_close(0, true)
        vim.api.nvim_command("edit +" .. line_number .. " " .. filename)
      end
    '';
  };
}
