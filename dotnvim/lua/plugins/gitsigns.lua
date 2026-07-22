local gitsigns = require("gitsigns")

gitsigns.setup({
  signs = {
    add = { text = "┃" },
    change = { text = "┃" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
  },
  preview_config = {
    relative = "cursor",
    row = 1,
    col = 0,
  },
})

local opts = { silent = true }

vim.keymap.set("n", "<Leader>gn", function()
  if vim.wo.diff then
    vim.cmd.normal({ "]c", bang = true })
    return
  end
  gitsigns.nav_hunk("next")
end, vim.tbl_extend("force", opts, { desc = "Next hunk" }))

vim.keymap.set("n", "<Leader>gp", function()
  if vim.wo.diff then
    vim.cmd.normal({ "[c", bang = true })
    return
  end
  gitsigns.nav_hunk("prev")
end, vim.tbl_extend("force", opts, { desc = "Previous hunk" }))

vim.keymap.set("n", "<Leader>gd", gitsigns.preview_hunk, vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
vim.keymap.set("n", "<Leader>gq", "<Cmd>Gitsigns setqflist all<CR>", vim.tbl_extend("force", opts, { desc = "Repository hunks quickfix" }))
vim.keymap.set("n", "<Leader>gs", gitsigns.stage_hunk, vim.tbl_extend("force", opts, { desc = "Stage/unstage hunk" }))
vim.keymap.set("x", "<Leader>gs", function()
  gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
vim.keymap.set("n", "<Leader>gx", gitsigns.reset_hunk, vim.tbl_extend("force", opts, { desc = "Reset/undo hunk" }))
vim.keymap.set("x", "<Leader>gx", function()
  gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
