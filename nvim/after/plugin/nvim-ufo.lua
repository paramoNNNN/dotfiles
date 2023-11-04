require("ufo").setup()

-- Using ufo provider need remap `zR` and `zM`.
vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
