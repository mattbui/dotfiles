local git_conflict = require("git-conflict")

git_conflict.setup({
  default_mappings = false,
})

local map = vim.keymap.set
local opts = { silent = true }

local function open_conflicts_quickfix()
  git_conflict.conflicts_to_qf_items(function(items)
    if #items == 0 then
      return
    end

    for _, item in ipairs(items) do
      if item.lnum and item.lnum > 0 then
        item.pattern = nil
      end
    end

    vim.fn.setqflist({}, "r", {
      items = items,
      title = "Git conflicts",
    })
    vim.cmd.copen()
  end)
end

map("n", "<Leader>c<", "<Plug>(git-conflict-ours)",
  vim.tbl_extend("force", opts, { desc = "Choose current change" }))
map("n", "<Leader>c>", "<Plug>(git-conflict-theirs)",
  vim.tbl_extend("force", opts, { desc = "Choose incoming change" }))
map("n", "<Leader>cb", "<Plug>(git-conflict-both)",
  vim.tbl_extend("force", opts, { desc = "Choose both changes" }))
map("n", "<Leader>cx", "<Plug>(git-conflict-none)",
  vim.tbl_extend("force", opts, { desc = "Choose neither change" }))
map("n", "<Leader>cn", "<Plug>(git-conflict-next-conflict)",
  vim.tbl_extend("force", opts, { desc = "Next conflict" }))
map("n", "<Leader>cp", "<Plug>(git-conflict-prev-conflict)",
  vim.tbl_extend("force", opts, { desc = "Previous conflict" }))
map("n", "<Leader>cq", open_conflicts_quickfix,
  vim.tbl_extend("force", opts, { desc = "Conflicts quickfix list" }))
