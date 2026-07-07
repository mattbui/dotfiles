local map = vim.keymap.set
local silent = { silent = true }

-- Buffers
map("n", "<S-j>", "<Cmd>bnext<CR>", silent)
map("n", "<S-k>", "<Cmd>bprevious<CR>", silent)
map("n", "<C-w>", "<Cmd>BufferClose<CR>", silent)
map("n", "gb", "<C-o>", { desc = "Jump back" })
map("n", "gt", "<C-i>")

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
map("n", "<Leader>/", "gcc", { remap = true })
map("x", "<Leader>/", "gc", { remap = true })

-- Insert mode completion and undo breakpoints
map("i", "<C-j>", "<C-n>")
map("i", "<C-k>", "<C-p>")

for _, key in ipairs({ ",", ".", "!", "?", ":" }) do
  map("i", key, key .. "<C-g>u")
end

map("i", "<Space>", "<Space><C-g>u")
map("i", "<C-w>", "<C-g>u<C-w>")
map("i", "<C-u>", "<C-g>u<C-u>")

-- Code block movement
map("n", "gm", "]m", { silent = true, desc = "Next method" })
map("n", "gM", "[m", { silent = true, desc = "Previous method" })
map("n", "gl", "]]", { silent = true, desc = "Next section" })
map("n", "gL", "[[", { silent = true, desc = "Previous section" })

-- Editing
map({ "i", "c" }, "jj", "<Esc>")
map("v", "<", "<gv")
map("v", ">", ">gv")
map("i", "<C-e>", "<End>")
map("i", "<C-a>", "<Home>")
map("c", "<C-a>", "<Home>")
map("c", "<C-e>", "<End>")
map("i", "<M-b>", "<S-Left>")
map("i", "<M-f>", "<S-Right>")
map("c", "<M-b>", "<S-Left>")
map("c", "<M-f>", "<S-Right>")

map("n", "<Leader>o", "o<Esc>")
map("n", "<Leader>O", "O<Esc>")

-- Windows
map("n", "<Leader>H", "<Cmd>leftabove vsplit<CR>", silent)
map("n", "<Leader>J", "<Cmd>rightbelow split<CR>", silent)
map("n", "<Leader>K", "<Cmd>leftabove split<CR>", silent)
map("n", "<Leader>L", "<Cmd>rightbelow vsplit<CR>", silent)
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
