if vim.fn.has("termguicolors") == 1 then
  vim.opt.termguicolors = true
end

local supported_colorschemes = {
  ["tokyonight-storm"] = true,
  ["rose-pine"] = true,
  ["rose-pine-moon"] = true,
  ["rose-pine-dawn"] = true,
}
local requested_colorscheme = vim.env.TERM_THEME
local colorscheme = supported_colorschemes[requested_colorscheme]
    and requested_colorscheme
  or "rose-pine-dawn"

require("rose-pine").setup({
  dark_variant = "main",
  extend_background_behind_borders = true,
  palette = {
    dawn = {
      -- Match the canonical Dawn foreground; the Neovim plugin still ships #464261.
      text = "#575279",
    },
  },
})

vim.cmd.colorscheme(colorscheme)
require("custom-colors").setup()
