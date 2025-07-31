{ config, ... }: {
  programs.nixvim = {
    plugins.lualine = {
      enable = true;
      settings = { options = { globalstatus = false; }; };
    };

    extraConfigLuaPost = ''
      local lualine = require('lualine')
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
            normal = { c = { bg = "${config.lib.stylix.colors.base00}" } },
            inactive = { c = { bg = "${config.lib.stylix.colors.base00}" } },
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
        n = "${config.lib.stylix.colors.base0D}",
        i = "${config.lib.stylix.colors.base0B}",
        v = "${config.lib.stylix.colors.base0E}",
        [''] = "${config.lib.stylix.colors.base0E}",
        V = "${config.lib.stylix.colors.base0E}",
        c = "${config.lib.stylix.colors.base0E}",
        no = "${config.lib.stylix.colors.base08}",
        s = "${config.lib.stylix.colors.base09}",
        S = "${config.lib.stylix.colors.base09}",
        [''] = "${config.lib.stylix.colors.base09}",
        ic = "${config.lib.stylix.colors.base0A}",
        R = "${config.lib.stylix.colors.base0E}",
        Rv = "${config.lib.stylix.colors.base0E}",
        cv = "${config.lib.stylix.colors.base08}",
        ce = "${config.lib.stylix.colors.base08}",
        r = "${config.lib.stylix.colors.base0D}",
        rm = "${config.lib.stylix.colors.base0D}",
        ['r?'] = "${config.lib.stylix.colors.base0D}",
        ['!'] = "${config.lib.stylix.colors.base08}",
        t = "${config.lib.stylix.colors.base0C}",
      }

      local function ins_left(component)
        table.insert(config.sections.lualine_c, component)
      end
      local function ins_left_inactive(component)
        table.insert(config.inactive_sections.lualine_c, component)
      end

      local function ins_right(component)
        table.insert(config.sections.lualine_x, component)
      end
      local function ins_right_inactive(component)
        table.insert(config.inactive_sections.lualine_x, component)
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
        color = { fg = "${config.lib.stylix.colors.base04}" , gui = 'bold' },
      }
      ins_left_inactive {
        'filename',
        path = 4,
        cond = conditions.buffer_not_empty,
        color = { fg = "${config.lib.stylix.colors.base04}" , gui = 'bold' },
      }

      ins_left {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        symbols = { error = ' ', warn = ' ', info = ' ' },
        diagnostics_color = {
          error = { fg = "${config.lib.stylix.colors.base08}"  },
          warn = { fg = "${config.lib.stylix.colors.base0A}"  },
          info = { fg = "${config.lib.stylix.colors.base0C}"  },
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
      ins_right_inactive {
        'filetype',
        colored = true;
      }

      lualine.setup(config)
    '';
  };
}
