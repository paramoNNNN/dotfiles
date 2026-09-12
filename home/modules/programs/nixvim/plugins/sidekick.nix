{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.sidekick-nvim ];

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
                require("sidekick.cli").toggle({ name = "codex", focus = true })
              end
            '';
            desc = "Toggle Codex chat";
          }
          {
            __unkeyed-1 = "<leader>af";
            __unkeyed-2.__raw = ''
              function()
                require("sidekick.cli").send({ msg = "{file}" })
              end
            '';
            desc = "Send file to Codex";
          }
        ];
        mode = [ "n" ];
      }
      {
        __unkeyed-1 = [
          {
            __unkeyed-1 = "<leader>as";
            __unkeyed-2.__raw = ''
              function()
                require("sidekick.cli").send({ msg = "{selection}" })
              end
            '';
            desc = "Send selection to Codex";
          }
        ];
        mode = [ "x" ];
      }
    ];

    extraConfigLua = ''
      require("sidekick").setup({
        -- Only use Sidekick's CLI integration; Copilot NES is not needed.
        nes = { enabled = false },
        cli = {
          tools = {
            codex = {},
          },
          win = {
            layout = "float",
            keys = {
              hide_ctrl_z = { "<c-z>", "hide", mode = "nt" },
            },
            float = {
              border = "rounded",
              width = 0.9,
              height = 0.85,
            },
          },
        },
      })
    '';
  };
}
