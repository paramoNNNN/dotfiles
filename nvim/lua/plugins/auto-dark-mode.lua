local integrations = {
  indent_blankline = {
    enabled = true,
    colored_indent_levels = true,
  },
  neotree = true,
}

local lazygit_config_path = "/Users/taha/.config/lazygit/config.yml"

function set_defaults()
  vim.g.lazygit_use_custom_config_file_path = 1
  vim.cmd("colorscheme catppuccin")
  require("lualine").setup({
    options = {
      theme = "catppuccin",
    },
  })
  require("notify").setup({ background_colour = "#000000" })
end

return {
  "f-person/auto-dark-mode.nvim",
  opts = {
    update_interval = 1000,
    set_dark_mode = function()
      vim.g.lazygit_config_file_path =
        { lazygit_config_path, "/Users/taha/.config/lazygit/themes/catppuccin-mocha-blue.yml" }
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        integrations = integrations,
      })
      set_defaults()
    end,
    set_light_mode = function()
      vim.g.lazygit_config_file_path =
        { lazygit_config_path, "/Users/taha/.config/lazygit/themes/catppuccin-latte-blue.yml" }
      require("catppuccin").setup({
        flavour = "latte",
        transparent_background = true,
        highlight_overrides = {
          all = function(colors)
            return {
              LineNr = { fg = colors.overlay1 },
            }
          end,
        },
        integrations = integrations,
      })
      set_defaults()
    end,
  },
}
