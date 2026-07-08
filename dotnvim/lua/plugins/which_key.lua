pcall(vim.cmd.packadd, "which-key.nvim")

local ok, wk = pcall(require, "which-key")
if not ok then
  vim.schedule(function()
    vim.notify("which-key.nvim is not available; run vim.pack update/repair", vim.log.levels.WARN)
  end)
  return
end

wk.setup({
  delay = 300,
  preset = "modern",
  icons = {
    mappings = false,
  },
  layout = {
    width = { min = 20, max = 28 },
    spacing = 3,
  },
  win = {
    no_overlap = false,
    border = "single",
  },
  triggers = {
    { "<Leader>", mode = { "n", "x" } },
    { "g",        mode = "n" },
  },
})

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map("n", "<Leader>W", "<Cmd>BufferCloseAllButCurrent<CR>", "Close other tabs")
map("n", "<Leader>Q", "<Cmd>q!<CR>", "Quit without save")
map("n", "<Leader>S", '<Cmd>source $MYVIMRC | echo "Saved Vim Settings"<CR>', "Save settings")
map("n", "<Leader>T", "<Cmd>BufferRestore<CR>", "Restore closed buffer")
map("n", "<Leader>V", "<Cmd>e $MYVIMRC<CR>", "Vim settings")

map("n", "<Leader>bp", "<Cmd>BufferTogglePermanent<CR>", "Toggle permanent")
map("n", "<Leader>bw", "<Cmd>BufferClose<CR>", "Close current")
map("n", "<Leader>bW", "<Cmd>BufferClosePreviews<CR>", "Close previews")
map("n", "<Leader>bT", "<Cmd>BufferRestore<CR>", "Restore closed")
map("n", "<Leader>bS", "<Cmd>BufferState<CR>", "Show state")

map("n", "<Leader>gr", "<Cmd>Grefresh<CR>", "Refresh")
map("n", "<Leader>gR", "<Cmd>Grh<CR>", "Reset")
map("n", "<Leader>gC", "<Cmd>Git commit<CR>", "Commit")
map("n", "<Leader>gP", "<Cmd>Gpush<CR>", "Push")
map("n", "<Leader>gL", "<Cmd>Gpull<CR>", "Pull")
map("n", "<Leader>ga", "<Cmd>Gwrite<CR>", "Add current file")
map("n", "<Leader>gU", "<Cmd>Git reset %<CR>", "Undo current file")
map("n", "<Leader>gA", "<Cmd>Git add .<CR>", "Add all")
map("n", "<Leader>gD", "<Cmd>Git diff<CR>", "Global diff")
map("n", "<Leader>gB", "<Cmd>Git blame<CR>", "Blame")
map("n", "<Leader>gS", "<Cmd>G<CR>", "Status")
map("n", "<Leader>gl", "<Cmd>Gclog -50<CR>", "Log")

map("n", "<Leader>cn", "<Cmd>cnext<CR>", "Quickfix next")
map("n", "<Leader>cp", "<Cmd>cprevious<CR>", "Quickfix previous")

map("n", "<Leader>ww", "<C-w>", "Window command")
map("n", "<Leader>wo", "<Cmd>wincmd o<CR>", "Only current")
map("n", "<Leader>wj", "<Cmd>wincmd j<CR>", "Move down")
map("n", "<Leader>wk", "<Cmd>wincmd k<CR>", "Move up")
map("n", "<Leader>wh", "<Cmd>wincmd h<CR>", "Move left")
map("n", "<Leader>wl", "<Cmd>wincmd l<CR>", "Move right")
map("n", "<Leader>wr", "<Cmd>wincmd r<CR>", "Rotate down/right")
map("n", "<Leader>wR", "<Cmd>wincmd R<CR>", "Rotate up/left")
map("n", "<Leader>wJ", "<Cmd>wincmd J<CR>", "Move bottom")
map("n", "<Leader>wK", "<Cmd>wincmd K<CR>", "Move top")
map("n", "<Leader>wH", "<Cmd>wincmd H<CR>", "Move left")
map("n", "<Leader>wL", "<Cmd>wincmd L<CR>", "Move right")

map("n", "<Leader>ib", "<Cmd>IPythonCellInsertBelow<CR>o", "Insert cell below")
map("n", "<Leader>ia", "<Cmd>IPythonCellInsertAbove<CR>o", "Insert cell above")
map("n", "<Leader>ii", "<Cmd>SlimeSend1 ipython<CR>", "IPython")
map("n", "<Leader>is", "<Cmd>call IPynbStart()<CR>", "Start")
map("n", "<Leader>ir", "<Cmd>call IPynbAutoReload()<CR>", "Autoreload")
map("n", "<Leader>im", "<Cmd>IPythonCellToMarkdown<CR>", "Markdown cell")
map("n", "<Leader>in", "<Cmd>IPythonCellNextCell<CR>", "Next cell")
map("n", "<Leader>ip", "<Cmd>IPythonCellPrevCell<CR>", "Previous cell")
map("n", "<Leader>ij", "<Cmd>IPythonCellNextCell<CR>", "Next cell")
map("n", "<Leader>ik", "<Cmd>IPythonCellPrevCell<CR>", "Previous cell")
map("n", "<Leader>iR", "<Cmd>IPythonCellRestart<CR>", "Restart")
map("n", "<Leader>id", "<Cmd>SlimeSend1 %debug<CR>", "Debug")
map("n", "<Leader>iq", "<Cmd>SlimeSend1 exit<CR>", "Quit")
map("n", "<Leader>ic", '<Cmd>SlimeSend0 "\\x03"<CR>', "Cancel")

wk.add({
  { "<Leader>/",   desc = "Comment",           mode = { "n", "x" } },
  { "<Leader>0",   hidden = true },
  { "<Leader>1",   hidden = true },
  { "<Leader>2",   hidden = true },
  { "<Leader>3",   hidden = true },
  { "<Leader>4",   hidden = true },
  { "<Leader>5",   hidden = true },
  { "<Leader>6",   hidden = true },
  { "<Leader>7",   hidden = true },
  { "<Leader>8",   hidden = true },
  { "<Leader>9",   hidden = true },
  { "<Leader>a",   desc = "Align preview" },
  { "<Leader>b",   group = "buffers" },
  { "<Leader>bp",  desc = "Toggle permanent" },
  { "<Leader>bS",  desc = "Show state" },
  { "<Leader>bT",  desc = "Restore closed" },
  { "<Leader>bw",  desc = "Close current" },
  { "<Leader>bW",  desc = "Close previews" },
  { "<Leader>c",   group = "code-actions" },
  { "<Leader>ca",  desc = "Code action" },
  { "<Leader>cf",  desc = "Format",            mode = { "n", "x" } },
  { "<Leader>cn",  desc = "Quickfix next" },
  { "<Leader>cp",  desc = "Quickfix previous" },
  { "<Leader>cr",  desc = "Rename variable" },
  { "<Leader>cs",  desc = "Sort imports" },
  { "<Leader>d",   desc = "Show diagnostic" },
  { "<Leader>g",   group = "git" },
  { "<Leader>gA",  desc = "Add all" },
  { "<Leader>gB",  desc = "Blame" },
  { "<Leader>gC",  desc = "Commit" },
  { "<Leader>gD",  desc = "Global diff" },
  { "<Leader>gP",  desc = "Push" },
  { "<Leader>gR",  desc = "Reset" },
  { "<Leader>gS",  desc = "Status" },
  { "<Leader>gU",  desc = "Undo current file" },
  { "<Leader>ga",  desc = "Add current file" },
  { "<Leader>gb",  desc = "Blame line" },
  { "<Leader>gcb", desc = "New branch" },
  { "<Leader>gco", desc = "Change branch" },
  { "<Leader>gd",  desc = "Preview hunk" },
  { "<Leader>gj",  desc = "Next hunk" },
  { "<Leader>gk",  desc = "Previous hunk" },
  { "<Leader>gl",  desc = "Log" },
  { "<Leader>gL",  desc = "Pull" },
  { "<Leader>gr",  desc = "Refresh" },
  { "<Leader>gs",  desc = "Stage hunk",        mode = { "n", "x" } },
  { "<Leader>gu",  desc = "Reset hunk",        mode = { "n", "x" } },
  { "<Leader>i",   group = "IPython" },
  { "<Leader>j",   desc = "Focus float" },
  { "<Leader>k",   desc = "Focus float" },
  { "<Leader>H",   desc = "Split left" },
  { "<Leader>J",   desc = "Split below" },
  { "<Leader>K",   desc = "Split above" },
  { "<Leader>L",   desc = "Split right" },
  { "<Leader>o",   desc = "Insert line below" },
  { "<Leader>O",   desc = "Insert line above" },
  { "<Leader>p",   desc = "Pick buffer" },
  { "<Leader>s",   group = "split/join",       mode = { "n", "x" } },
  { "<Leader>sj",  desc = "Split arguments",   mode = { "n", "x" } },
  { "<Leader>sk",  desc = "Join arguments",    mode = { "n", "x" } },
  { "<Leader>ss",  desc = "Toggle split/join", mode = { "n", "x" } },
  { "<Leader>w",   group = "windows" },
  { "<Leader>wH",  desc = "Move left" },
  { "<Leader>wJ",  desc = "Move bottom" },
  { "<Leader>wK",  desc = "Move top" },
  { "<Leader>wL",  desc = "Move right" },
  { "<Leader>wR",  desc = "Rotate up/left" },
  { "<Leader>wh",  desc = "Move left" },
  { "<Leader>wj",  desc = "Move down" },
  { "<Leader>wk",  desc = "Move up" },
  { "<Leader>wl",  desc = "Move right" },
  { "<Leader>wo",  desc = "Only current" },
  { "<Leader>wr",  desc = "Rotate down/right" },
  { "g",           group = "goto" },
  { "gO",          desc = "Document symbols" },
})
