{
  programs.nixvim.plugins = {
    which-key.settings.spec = [{
      __unkeyed-1 = [
        {
          __unkeyed-1 = "<leader>l";
          group = "LSP";
        }
        {
          __unkeyed-1 = "<leader>lr";
          __unkeyed-2 = "<Cmd>LspRestart<CR>";
          desc = "Restart";
        }
        {
          __unkeyed-1 = "<leader>li";
          __unkeyed-2 = "<Cmd>LspInfo<CR>";
          desc = "Info";
        }

        {
          __unkeyed-1 = "K";
          __unkeyed-2 = "<Cmd>Lspsaga hover_doc<CR>";
          desc = "View documentation";
        }
        {
          __unkeyed-1 = "vrr";
          __unkeyed-2 = "<Cmd>Telescope lsp_references<CR>";
          desc = "View references";
        }
        {
          __unkeyed-1 = "gd";
          __unkeyed-2 = "<Cmd>Telescope lsp_definitions<CR>";
          desc = "View definitions";
        }
        {
          __unkeyed-1 = "gi";
          __unkeyed-2 = "<Cmd>Telescope lsp_implementations<CR>";
          desc = "View implementations";
        }
        {
          __unkeyed-1 = "gt";
          __unkeyed-2 = "<Cmd>Telescope lsp_type_definitions<CR>";
          desc = "View type definitions";
        }
        {
          __unkeyed-1 = "vca";
          __unkeyed-2 = "<Cmd>Lspsaga code_action<CR>";
          desc = "View code actions";
        }
        {
          __unkeyed-1 = "vrn";
          __unkeyed-2 = "<Cmd>Lspsaga rename<CR>";
          desc = "Rename symbol";
        }
      ];
      mode = [ "n" ];
    }];

    lsp = {
      enable = true;
      servers = {
        ts_ls.enable = true;
        cssls.enable = true;
        # TODO:
        # tailwindcss.enable = true;
        html.enable = true;
        astro.enable = true;
        svelte.enable = false;
        vuels.enable = false;
        pyright.enable = true;
        marksman.enable = true;
        nil_ls.enable = true;
        dockerls.enable = true;
        bashls.enable = true;
        yamlls.enable = true;
        biome.enable = true;
        lua_ls = {
          enable = true;
          settings.telemetry.enable = false;
        };
      };
    };

    lspsaga = {
      enable = true;
      lightbulb.enable = false;
      codeAction = { showServerName = true; };
      symbolInWinbar.enable = false;
    };
  };
}

