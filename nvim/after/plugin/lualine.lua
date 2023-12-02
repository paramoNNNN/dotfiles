require("lualine").setup({
  options = {
    globalstatus = true,
  },
  sections = {
    lualine_b = { "diagnostics" },
    lualine_c = { { "filename", path = 4 } },
    lualine_x = { "filetype" },
  },
})
