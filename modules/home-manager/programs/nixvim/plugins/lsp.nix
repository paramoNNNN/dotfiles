{
    programs.nixvim.plugins.lsp = {
      enable = true;
      servers = {
        ts_ls.enable = true;
        cssls.enable = true;
        tailwindcss.enable = true;
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
        ltex = {
          enable = true;
          settings = {
            enabled = [ "astro" "html" "latex" "markdown" "text" "tex" "gitcommit" ];
            completionEnabled = true;
            language = "en-US";
          };
        };
        lua_ls = {
          enable = true;
          settings.telemetry.enable = false;
        };
      };
    };
}

