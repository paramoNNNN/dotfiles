require("lualine").setup({
  options = {
    globalstatus = true,
  },
  sections = {
    lualine_b = { "diagnostics" },
    lualine_x = { "filetype" },
  },
})
