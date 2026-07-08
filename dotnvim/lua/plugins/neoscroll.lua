require("neoscroll").setup({
  mappings = { "<C-u>", "<C-d>", "zt", "zz", "zb" },
  hide_cursor = true,
  stop_eof = true,
  respect_scrolloff = false,
  cursor_scrolls_alone = true,
  easing = false,
  easing_function = function(x)
    return x ^ 4
  end,
})
