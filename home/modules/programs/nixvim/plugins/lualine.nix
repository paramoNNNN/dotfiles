{
  programs.nixvim = {
    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "catppuccin";
          globalstatus = true;
        };
      };
    };

    extraConfigLuaPost = ''
      local lualine = require('lualine')
      local colors = require("catppuccin.palettes").get_palette('latte')

      local conditions = {
        buffer_not_empty = function()
          return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
        end,
        hide_in_width = function()
          return vim.fn.winwidth(0) > 80
        end,
        check_git_workspace = function()
          local filepath = vim.fn.expand('%:p:h')
          local gitdir = vim.fn.finddir('.git', filepath .. ';')
          return gitdir and #gitdir > 0 and #gitdir < #filepath
        end,
      }

      local config = {
        options = {
          component_separators = "",
          section_separators = "",
          theme = {
            normal = { c = { fg = colors.fg, bg = colors.bg } },
            inactive = { c = { fg = colors.fg, bg = colors.bg } },
          },
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = {},
          lualine_x = {},
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_y = {},
          lualine_z = {},
          lualine_c = {},
          lualine_x = {},
        },
      }

      local mode_color = {
        n = colors.blue,
        i = colors.green,
        v = colors.pink,
        [''] = colors.pink,
        V = colors.pink,
        c = colors.flamingo,
        no = colors.red,
        s = colors.peach,
        S = colors.peach,
        [''] = colors.peach,
        ic = colors.yellow,
        R = colors.mauve,
        Rv = colors.mauve,
        cv = colors.red,
        ce = colors.red,
        r = colors.sky,
        rm = colors.sky,
        ['r?'] = colors.sky,
        ['!'] = colors.red,
        t = colors.sapphire,
      }

      local function ins_left(component)
        table.insert(config.sections.lualine_c, component)
      end

      local function ins_right(component)
        table.insert(config.sections.lualine_x, component)
      end

      ins_left {
        function()
          return ''
        end,
        color = function()
          return { fg = mode_color[vim.fn.mode()] }
        end,
        padding = { left = 1, right = 0 },
      }

      ins_left {
        'filename',
        path = 4,
        cond = conditions.buffer_not_empty,
        color = { fg = colors.text, gui = 'bold' },
      }

      ins_left {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        symbols = { error = ' ', warn = ' ', info = ' ' },
        diagnostics_color = {
          error = { fg = colors.red },
          warn = { fg = colors.yellow },
          info = { fg = colors.sky },
        },
      }

      ins_left {
        function()
          return '%='
        end,
      }

      ins_right {
        'filetype',
        colored = true;
      }

      lualine.setup(config)
    '';
  };
}
