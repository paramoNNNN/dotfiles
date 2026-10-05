{ config, ... }:
{
  programs.nixvim = {
    highlightOverride.TelescopeResultsComment.fg =
      if config.theme.variant == "light" then "#706e69" else "#${config.lib.stylix.colors.base04}";

    plugins.which-key.settings.spec = [
      {
        __unkeyed-1 = [
          {
            __unkeyed-1 = "<leader>f";
            group = "Telescope";
          }
          {
            __unkeyed-1 = "<leader>fa";
            __unkeyed-2 = "<Cmd>AdvancedGitSearch<CR>";
            desc = "Git search";
          }
          {
            __unkeyed-1 = "<leader>ff";
            __unkeyed-2 = "<Cmd>Telescope find_files<CR>";
            desc = "Find files";
          }
          {
            __unkeyed-1 = "<leader>fg";
            __unkeyed-2 = "<Cmd>Telescope live_grep_args<CR>";
            desc = "Live grep with arguments";
          }
          {
            __unkeyed-1 = "<leader>fh";
            __unkeyed-2 = "<Cmd>Telescope help_tags<CR>";
            desc = "Help tags";
          }
          {
            __unkeyed-1 = "<leader>fo";
            __unkeyed-2 = "<Cmd>Telescope oldfiles<CR>";
            desc = "Recent files";
          }
          {
            __unkeyed-1 = "<leader>fq";
            __unkeyed-2 = "<Cmd>Telescope quickfix<CR>";
            desc = "Quickfix";
          }
          {
            __unkeyed-1 = "<leader>fr";
            __unkeyed-2 = "<Cmd>Telescope resume<CR>";
            desc = "Resume last search";
          }
          {
            __unkeyed-1 = "<leader><leader>";
            __unkeyed-2 = "<Cmd>Telescope buffers<CR>";
            desc = "Buffers";
          }
        ];
        mode = [ "n" ];
      }
    ];

    plugins.telescope = {
      enable = true;
      extensions = {
        file-browser.enable = true;
        fzf-native.enable = true;
        live-grep-args.enable = true;
      };
      enabledExtensions = [ "advanced_git_search" ];
      settings = {
        defaults = {
          path_display = [ "filename_first" ];
          layout_strategy = "flex";
          layout_config = {
            width = 0.95;
            height = 0.85;
            flex = {
              flip_columns = 120;
              flip_lines = 30;
            };
            horizontal = {
              preview_width = 0.4;
              preview_cutoff = 120;
            };
            vertical = {
              preview_height = 0.4;
              preview_cutoff = 30;
            };
          };
          mappings = {
            n = {
              "<M-p>" = {
                __raw = ''require("telescope.actions.layout").toggle_preview'';
              };
              "<C-q>" = {
                __raw = ''require("telescope.actions").send_selected_to_qflist + require("telescope.actions").open_qflist'';
              };
            };
            i = {
              "<M-p>" = {
                __raw = ''require("telescope.actions.layout").toggle_preview'';
              };
              "<C-q>" = {
                __raw = ''require("telescope.actions").send_selected_to_qflist + require("telescope.actions").open_qflist'';
              };
            };
          };
        };
        pickers = {
          find_files = {
            find_command = [
              "rg"
              "--files"
              "--hidden"
              "--glob"
              "!**/.git/*"
            ];
          };
          buffers = {
            sort_lastused = true;
            sort_mru = true;
            mappings.i."<C-d>" = {
              __raw = ''require("telescope.actions").delete_buffer'';
            };
          };
        };
      };
    };
  };

}
