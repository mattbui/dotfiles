require("ibl").setup({
  exclude = {
    filetypes = {
      "help",
      "which_key",
      "fugitive",
      "man",
      "checkhealth",
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
