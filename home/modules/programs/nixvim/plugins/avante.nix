{ pkgs, ... }:
let
  avanteCodexAcp = pkgs.callPackage ./avante-codex-acp.nix { };
in
{
  programs.nixvim = {
    extraPackages = with pkgs; [
      ripgrep
      fd
      curl
      gnutar
      avanteCodexAcp
    ];

    opts.laststatus = 3;

    plugins = {
      avante = {
        enable = true;
        settings = {
          provider = "codex";
          auto_suggestions_provider = "codex";
          mode = "agentic";

          acp_providers.codex = {
            command = "${avanteCodexAcp}/bin/codex-acp";
            args = [ ];
            env.NODE_NO_WARNINGS = "1";
          };

          instructions_file = "avante.md";

          windows = {
            position = "right";
            width = 45;
            input.height = 10;
            ask = {
              floating = true;
              border = "rounded";
              start_insert = true;
            };
          };
        };
      };

      render-markdown = {
        enable = true;
        settings.file_types = [
          "markdown"
          "Avante"
        ];
      };
    };

    # Avante's full conversation is a multi-window layout and cannot be made
    # into one native float. Zen mode gives it the full editor after this
    # floating prompt is submitted, which works well on a small display.
    plugins.which-key.settings.spec = [
      {
        __unkeyed-1 = [
          {
            __unkeyed-1 = "<leader>a";
            group = "AI";
          }
          {
            __unkeyed-1 = "<leader>aa";
            __unkeyed-2.__raw = ''
              function()
                require("avante.api").zen_mode()
              end
            '';
            desc = "Avante (floating prompt / full view)";
          }
          {
            __unkeyed-1 = "<leader>at";
            __unkeyed-2 = "<Cmd>AvanteToggle<CR>";
            desc = "Toggle Avante sidebar";
          }
        ];
        mode = [ "n" ];
      }
    ];
  };
}
