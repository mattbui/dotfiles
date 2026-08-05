local neoscroll = require("neoscroll")

neoscroll.setup({
  mappings = { "<C-u>", "<C-d>" },
  hide_cursor = true,
  stop_eof = true,
  respect_scrolloff = false,
  cursor_scrolls_alone = true,
  easing = "linear",
})

vim.keymap.set({ "n", "x" }, "<PageUp>", function()
  neoscroll.ctrl_u({ duration = 250 })
end, { silent = true })

vim.keymap.set({ "n", "x" }, "<PageDown>", function()
  neoscroll.ctrl_d({ duration = 250 })
end, { silent = true })
