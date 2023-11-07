return {
  "f-person/auto-dark-mode.nvim",
  config = {
    update_interval = 1000,
    set_dark_mode = function()
      vim.cmd("colorscheme carbonfox")
      require("lualine").setup({
        options = {
          theme = "carbonfox",
        },
      })
    end,
    set_light_mode = function()
      require("catppuccin").setup({
        flavour = "latte",
        integrations = {
          indent_blankline = {
            enabled = true,
            colored_indent_levels = true,
          },
          neotree = true,
        },
      })
      vim.cmd("colorscheme catppuccin")
      require("lualine").setup({
        options = {
          theme = "catppuccin",
        },
      })
    end,
  },
}
