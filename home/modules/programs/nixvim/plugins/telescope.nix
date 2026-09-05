{
  programs.nixvim = {

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
            __unkeyed-1 = "<leader>fq";
            __unkeyed-2 = "<Cmd>Telescope quickfix<CR>";
            desc = "Quickfix";
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
        live-grep-args.enable = true;
      };
      enabledExtensions = [ "advanced_git_search" ];
      settings = {
        defaults = {
          mappings = {
            n = {
              "<C-q>" = {
                __raw = ''require("telescope.actions").send_selected_to_qflist + require("telescope.actions").open_qflist'';
              };
            };
            i = {
              "<C-d>" = {
                __raw = ''
                  require("telescope.actions").delete_buffer
                '';
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
          };
        };
      };
    };
  };

}
