{ inputs, ... }: {
  imports = [ inputs.nixvim.homeManagerModules.nixvim ./plugins ];

  home.shellAliases.v = "nvim";

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    luaLoader.enable = true;

    keymaps = [
      {
        key = "J";
        action = ":m '>+1<CR>gv=gv";
        options = { desc = "Move selected line up"; };
      }
      {
        key = "K";
        action = ":m '>-2<CR>gv=gv";
        options = { desc = "Move selected line down"; };
      }

      {
        key = "<leader>p";
        action = "[['_dP]]";
        options = { desc = "Paste without yanking"; };
      }

      # TODO:
      {
        key = "<leader>s";
        action = "[[:%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>]]";
        options = { desc = "Replace"; };
      }
      {
        key = "<leader>S";
        action = "[[:s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>]]";
        options = { desc = "Replace on current line"; };
      }
    ];

    colorschemes = {
      catppuccin = {
        enable = true;
        luaConfig.post = ''
          require("catppuccin").setup({
            highlight_overrides = {
              all = function(colors)
                return {
                  LineNr = { fg = colors.overlay1 },
                }
              end,
            },
          })
        '';
        settings = {
          flavour = "mocha";
          transparent_background = true;
          integrations = {
            cmp = true;
            gitsigns = true;
            treesitter = true;
            notify = true;
            indent_blankline = {
              enabled = true;
              colored_indent_levels = true;
            };
            mini = { enabled = true; };
            neotree = true;
            rainbow_delimiters = true;
            telescope = { enabled = true; };
            ufo = true;
            which_key = true;
          };
        };
      };
    };

    clipboard.register = "unnamedplus";

    globals = { mapleader = " "; };

    opts = {
      guicursor = "i:ver30-iCursor-blinkwait300-blinkon200-blinkoff150";
      cmdheight = 0;

      nu = true;
      relativenumber = true;

      tabstop = 4;
      softtabstop = 4;
      shiftwidth = 4;
      expandtab = true;

      smartindent = true;

      wrap = false;

      swapfile = false;
      backup = false;

      hlsearch = false;
      incsearch = true;

      termguicolors = true;

      scrolloff = 8;
      signcolumn = "yes";

      updatetime = 50;

      foldcolumn = "1";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;

      spelllang = "en_us";
      spell = true;
    };
  };
}
