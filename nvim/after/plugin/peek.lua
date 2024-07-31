require("peek").setup({
  auto_load = true,
  -- entering another markdown buffer
  close_on_bdelete = true, -- close preview window on buffer delete
  theme = "light",
  update_on_change = true,
  app = "browser", -- 'webview', 'browser', string or a table of strings
  filetype = { "markdown" },
  throttle_at = 200000,
  throttle_time = "auto",
})
