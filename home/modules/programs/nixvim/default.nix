{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./plugins
  ];

  home.shellAliases.v = "nvim";

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    luaLoader.enable = true;

    extraConfigLua = ''
      vim.env.SHELL = vim.o.shell
    '';

    keymaps = [
      {
        key = "J";
        mode = "x";
        action = ":m '>+1<CR>gv=gv";
        options = {
          desc = "Move selected lines down";
        };
      }
      {
        key = "K";
        mode = "x";
        action = ":m '<-2<CR>gv=gv";
        options = {
          desc = "Move selected lines up";
        };
      }
      {
        key = "<leader>s";
        action = ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>";
        options = {
          desc = "Replace";
        };
      }
      {
        key = "<leader>S";
        action = ":s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>";
        options = {
          desc = "Replace on current line";
        };
      }
    ];

    clipboard.register = "unnamedplus";

    globals = {
      mapleader = " ";
    };

    diagnostic.settings = {
      severity_sort = true;
    };

    opts = {
      shell = "${pkgs.bash}/bin/bash";
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

      updatetime = 300;

      foldcolumn = "0";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
      foldmethod = "expr";
      foldexpr = "v:lua.vim.treesitter.foldexpr()";
      foldtext = "";

      spelllang = "en_us";
      spell = true;
    };
  };
}
