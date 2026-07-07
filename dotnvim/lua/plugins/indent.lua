require("ibl").setup({
  exclude = {
    filetypes = {
      "help",
      "which_key",
      "fugitive",
      "man",
    },
    buftypes = {
      "terminal",
    },
  },
  indent = {
    char = "▏",
    highlight = {
      "Whitespace",
    },
  },
  scope = {
    enabled = false,
  },
  whitespace = {
    remove_blankline_trail = true,
  },
})

local indentscope = require("mini.indentscope")

indentscope.setup({
  draw = {
    animation = indentscope.gen_animation.none(),
    delay = 0,
  },
  options = {
    try_as_border = false,
  },
  symbol = "▏",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MiniIndentscopeDisable", { clear = true }),
  pattern = {
    "help",
    "which_key",
    "fugitive",
    "man",
  },
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("MiniIndentscopeTerminalDisable", { clear = true }),
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
})
