vim.g.mapleader = " "

vim.cmd.filetype({ args = { "plugin", "indent", "on" } })

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.fillchars:append({ vert = "│", eob = " " })
vim.opt.list = true
vim.opt.listchars:append({ eol = "⤦", trail = "·", precedes = "«", extends = "»", tab = "▸ " })
vim.opt.wrap = false
vim.opt.pumheight = 10
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 5
vim.opt.showtabline = 2
vim.opt.showmode = false

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Navigation and editing
vim.opt.mouse = "a"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.iskeyword:append("-")
vim.opt.inccommand = "split"
vim.opt.wildoptions:remove("pum")

vim.opt.laststatus = 3

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Files and persistence
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

-- Responsiveness and messages
vim.opt.updatetime = 300
vim.opt.timeoutlen = 600
vim.opt.shortmess:append("c")
vim.opt.shortmess:append("I")
vim.opt.clipboard:append("unnamedplus")
