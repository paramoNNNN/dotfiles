require("mini.cursorword").setup()
require("mini.pairs").setup()
require("mini.comment").setup({
  options = {
    custom_commentstring = function()
      return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
    end,
  },
})
require("mini.surround").setup()
