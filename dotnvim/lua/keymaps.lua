local map = vim.keymap.set
local silent = { silent = true }

-- Buffers
map("n", "<S-j>", "<Cmd>bnext<CR>", silent)
map("n", "<S-k>", "<Cmd>bprevious<CR>", silent)
map("n", "<C-w>", "<Cmd>BufferClose<CR>", silent)
map("n", "<Tab>", "<C-i>", { desc = "Jump forward" })
map("n", "<S-Tab>", "<C-o>", { desc = "Jump back" })

-- Yank helpers
map("n", "YY", "<Cmd>%y<CR>", silent)
map("x", "Y", ":YankRelativePathRange<CR>", silent)
map("x", "<Leader>y", ":YankAbsolutePathRange<CR>", silent)
map("n", "yt", "<Cmd>YankRelativePathTag<CR>", silent)
map("n", "yT", "<Cmd>YankAbsolutePathTag<CR>", silent)
map("n", "yp", "<Cmd>YankRelativePath<CR>", silent)
map("n", "yP", "<Cmd>YankAbsolutePath<CR>", silent)
map("n", "yl", "<Cmd>YankRelativePathLine<CR>", silent)
map("n", "yL", "<Cmd>YankAbsolutePathLine<CR>", silent)

-- Search
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<Esc>", "<Cmd>nohlsearch<CR>", silent)
map("n", "<C-c>", "<Cmd>nohlsearch<CR>", silent)

-- Comments
map({ "n", "x" }, "<Leader>/", function()
  local keys = require("vim._comment").operator()
  return vim.fn.mode() == "n" and keys .. "_" or keys
end, { expr = true, desc = "Comment" })

-- Insert mode completion and undo breakpoints
map("i", "<C-j>", "<C-n>")
map("i", "<C-k>", "<C-p>")

-- Command-line history
map("c", "<C-Up>", "<C-p>")
map("c", "<C-Down>", "<C-n>")

for _, key in ipairs({ ",", ".", "!", "?", ":" }) do
  map("i", key, key .. "<C-g>u")
end

map("i", "<Space>", "<Space><C-g>u")
map("i", "<C-w>", "<C-g>u<C-w>")
map("i", "<C-u>", "<C-g>u<C-u>")

-- Editing
map({ "i", "c" }, "jj", "<Esc>")
map("v", "<", "<gv")
map("v", ">", ">gv")
map({ "i", "c" }, "<C-e>", "<End>")
map({ "i", "c" }, "<C-a>", "<Home>")
map({ "i", "c" }, "<M-b>", "<S-Left>")
map({ "i", "c" }, "<M-f>", "<S-Right>")

map("n", "<Leader>o", "o<Esc>", { desc = "Insert line below" })
map("n", "<Leader>O", "O<Esc>", { desc = "Insert line above" })

-- Windows
map("n", "<Leader>H", "<Cmd>leftabove vsplit<CR>", { silent = true, desc = "Split left" })
map("n", "<Leader>J", "<Cmd>rightbelow split<CR>", { silent = true, desc = "Split below" })
map("n", "<Leader>K", "<Cmd>leftabove split<CR>", { silent = true, desc = "Split above" })
map("n", "<Leader>L", "<Cmd>rightbelow vsplit<CR>", { silent = true, desc = "Split right" })
map("n", "<Leader>ww", "<C-w>", { silent = true, desc = "Window command" })
map("n", "<Leader>wo", "<Cmd>wincmd o<CR>", { silent = true, desc = "Only current" })
map("n", "<Leader>wj", "<Cmd>wincmd j<CR>", { silent = true, desc = "Move down" })
map("n", "<Leader>wk", "<Cmd>wincmd k<CR>", { silent = true, desc = "Move up" })
map("n", "<Leader>wh", "<Cmd>wincmd h<CR>", { silent = true, desc = "Move left" })
map("n", "<Leader>wl", "<Cmd>wincmd l<CR>", { silent = true, desc = "Move right" })
map("n", "<Leader>wr", "<Cmd>wincmd r<CR>", { silent = true, desc = "Rotate down/right" })
map("n", "<Leader>wR", "<Cmd>wincmd R<CR>", { silent = true, desc = "Rotate up/left" })
map("n", "<Leader>wJ", "<Cmd>wincmd J<CR>", { silent = true, desc = "Move bottom" })
map("n", "<Leader>wK", "<Cmd>wincmd K<CR>", { silent = true, desc = "Move top" })
map("n", "<Leader>wH", "<Cmd>wincmd H<CR>", { silent = true, desc = "Move left" })
map("n", "<Leader>wL", "<Cmd>wincmd L<CR>", { silent = true, desc = "Move right" })
map("n", "=", "<Cmd>vertical resize +2<CR>", silent)
map("n", "-", "<Cmd>vertical resize -2<CR>", silent)
map("n", "+", "<Cmd>resize +2<CR>", silent)
map("n", "_", "<Cmd>resize -2<CR>", silent)

-- Save and quit
map("n", "<C-s>", "<Cmd>w<CR>", silent)
map("i", "<C-s>", "<Esc><Cmd>w<CR>", silent)
map("n", "<C-q>", "<Cmd>q<CR>", silent)
map("i", "<C-q>", "<Esc><Cmd>q<CR>", silent)
map("t", "<C-q>", "<C-\\><C-n><Cmd>bw!<CR>", silent)
map("n", "<Leader>Q", "<Cmd>q!<CR>", { silent = true, desc = "Quit without save" })
map("n", "<Leader>,", "<Cmd>e $MYVIMRC<CR>", { silent = true, desc = "Vim settings" })

-- Quickfix
map("n", "<PageDown>", "<Cmd>cnext<CR>", { silent = true, desc = "Quickfix next" })
map("n", "<PageUp>", "<Cmd>cprevious<CR>", { silent = true, desc = "Quickfix previous" })
map("n", "<S-PageDown>", "<Cmd>5cnext<CR>", { silent = true, desc = "Quickfix next x5" })
map("n", "<S-PageUp>", "<Cmd>5cprevious<CR>", { silent = true, desc = "Quickfix previous x5" })
