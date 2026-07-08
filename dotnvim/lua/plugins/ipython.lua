vim.g.slime_target = "tmux"
vim.g.slime_python_ipython = 1
vim.g.slime_default_config = {
  socket_name = vim.fn.get(vim.fn.split(vim.env.TMUX or "", ","), 0),
  target_pane = "{top-right}",
}
vim.g.slime_dont_ask_default = 1

vim.g.ipython_cell_tag = { "# %%", "#%%", "# <codecell>" }
vim.g.ipython_cell_insert_tag = "# %%"

vim.g.jupytext_fmt = "py:percent"
vim.g.jupytext_opts = [[--update-metadata '{"jupytext": {"cell_markers": "\"\"\""}}']]

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

local function start_ipynb()
  vim.fn.system("tmux split-window -fh -p 40 -c " .. vim.fn.shellescape(vim.fn.expand("%:p:h")))
  vim.cmd("silent SlimeSend1 ipython")
  vim.fn.system("tmux last-pane")
end

local function autoreload_ipynb()
  vim.cmd("silent SlimeSend1 %load_ext autoreload")
  vim.cmd("silent SlimeSend1 %autoreload 2")
end

local function set_buffer_mappings()
  vim.keymap.set("n", "<Leader><CR>", "<Cmd>IPythonCellExecuteCellVerboseJump<CR>", {
    buffer = true,
    silent = true,
    desc = "Execute cell",
  })
  vim.keymap.set("n", "<CR>", "<Plug>SlimeLineSend", { buffer = true, remap = true })
  vim.keymap.set("x", "<CR>", "<Plug>SlimeRegionSend", { buffer = true, remap = true })
end

map("<Leader>ib", "<Cmd>IPythonCellInsertBelow<CR>o", "Insert cell below")
map("<Leader>ia", "<Cmd>IPythonCellInsertAbove<CR>o", "Insert cell above")
map("<Leader>ii", "<Cmd>SlimeSend1 ipython<CR>", "IPython")
map("<Leader>is", start_ipynb, "Start")
map("<Leader>ir", autoreload_ipynb, "Autoreload")
map("<Leader>im", "<Cmd>IPythonCellToMarkdown<CR>", "Markdown cell")
map("<Leader>in", "<Cmd>IPythonCellNextCell<CR>", "Next cell")
map("<Leader>ip", "<Cmd>IPythonCellPrevCell<CR>", "Previous cell")
map("<Leader>ij", "<Cmd>IPythonCellNextCell<CR>", "Next cell")
map("<Leader>ik", "<Cmd>IPythonCellPrevCell<CR>", "Previous cell")
map("<Leader>iR", "<Cmd>IPythonCellRestart<CR>", "Restart")
map("<Leader>id", "<Cmd>SlimeSend1 %debug<CR>", "Debug")
map("<Leader>iq", "<Cmd>SlimeSend1 exit<CR>", "Quit")
map("<Leader>ic", '<Cmd>SlimeSend0 "\\x03"<CR>', "Cancel")

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles_ipython", { clear = true }),
  pattern = "python",
  callback = set_buffer_mappings,
})
