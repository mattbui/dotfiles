if vim.fn.has("termguicolors") == 1 then
  vim.opt.termguicolors = true
end

vim.cmd.colorscheme("tokyonight-storm")
require("custom-colors").setup()
