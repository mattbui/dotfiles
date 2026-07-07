local map = vim.keymap.set
local silent = { silent = true }

map("n", "<S-k>", "<Cmd>BufferPrevious<CR>", silent)
map("n", "<S-j>", "<Cmd>BufferNext<CR>", silent)
map("n", "<S-l>", "<Cmd>BufferMoveNext<CR>", silent)
map("n", "<S-h>", "<Cmd>BufferMovePrevious<CR>", silent)
map("n", "<C-w>", "<Cmd>BufferClose<CR>", silent)

for i = 1, 9 do
  map("n", "<Leader>" .. i, "<Cmd>BufferGoto " .. i .. "<CR>", silent)
end

map("n", "<Leader>0", "<Cmd>BufferLast<CR>", silent)
map("n", "<Leader>p", "<Cmd>BufferPick<CR>", silent)

require("barbar").setup({
  tabpages = false,

  icons = {
    button = "⨉",
    scroll = {
      left = "",
      right = "",
    },

    filetype = {
      custom_colors = true,
    },

    separator = {
      left = "▎",
    },
    gitsigns = {
      added = { enabled = true, icon = "+" },
      changed = { enabled = true, icon = "~" },
      deleted = { enabled = true, icon = "-" },
    },
  },

  no_name_title = "unnamed",
})
