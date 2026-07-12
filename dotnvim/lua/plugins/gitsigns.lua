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
    border = "single",
    relative = "cursor",
    row = 1,
    col = 0,
  },
})

local opts = { silent = true }

vim.keymap.set("n", "<Leader>gj", function()
  if vim.wo.diff then
    vim.cmd.normal({ "]c", bang = true })
    return
  end
  gitsigns.nav_hunk("next")
end, vim.tbl_extend("force", opts, { desc = "Next hunk" }))

vim.keymap.set("n", "<Leader>gk", function()
  if vim.wo.diff then
    vim.cmd.normal({ "[c", bang = true })
    return
  end
  gitsigns.nav_hunk("prev")
end, vim.tbl_extend("force", opts, { desc = "Previous hunk" }))

vim.keymap.set("n", "<Leader>gd", gitsigns.preview_hunk, vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
vim.keymap.set("n", "<Leader>gs", gitsigns.stage_hunk, vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
vim.keymap.set("x", "<Leader>gs", function()
  gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
vim.keymap.set("n", "<Leader>gu", gitsigns.reset_hunk, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
vim.keymap.set("x", "<Leader>gu", function()
  gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
vim.keymap.set("n", "<Leader>gb", gitsigns.blame_line, vim.tbl_extend("force", opts, { desc = "Blame line" }))
