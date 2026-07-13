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
  },
  triggers = {
    { "<Leader>", mode = { "n", "x" } },
    { "g",        mode = "n" },
  },
})

wk.add({
  { "<Leader>0", hidden = true },
  { "<Leader>1", hidden = true },
  { "<Leader>2", hidden = true },
  { "<Leader>3", hidden = true },
  { "<Leader>4", hidden = true },
  { "<Leader>5", hidden = true },
  { "<Leader>6", hidden = true },
  { "<Leader>7", hidden = true },
  { "<Leader>8", hidden = true },
  { "<Leader>9", hidden = true },
  { "<Leader>b", group = "buffers" },
  { "<Leader>f", group = "find" },
  { "<Leader>g", group = "git" },
  { "<Leader>i", group = "ipython" },
  { "<Leader>l", group = "lsp" },
  { "<Leader>w", group = "windows" },
  { "g",         group = "goto" },
  { "gO",        desc = "Document symbols" },
})
