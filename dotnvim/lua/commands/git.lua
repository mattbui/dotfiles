local function fugitive_head()
  local ok, head = pcall(vim.fn.FugitiveHead)
  if not ok then
    return ""
  end
  return head
end

local function reload_fugitive_status()
  if vim.fn.exists("*fugitive#ReloadStatus") == 1 then
    pcall(vim.fn["fugitive#ReloadStatus"])
  end
end

local function git_commit()
  vim.fn.inputsave()
  local message = vim.fn.input("Commit message: ")
  vim.fn.inputrestore()

  if message == "" then
    return
  end

  vim.cmd("FloatermNew! --autoclose=2 git commit -m " .. vim.fn.shellescape(message) .. " && exit")
end

local function git_refresh()
  pcall(function()
    vim.cmd("Gitsigns refresh")
  end)
  reload_fugitive_status()
end

local function git_push_current_branch()
  local head = fugitive_head()
  if head ~= "" then
    print("Pushing to " .. head)
  else
    print("Pushing current branch")
  end

  vim.cmd("Git -c push.default=current push")
end

local function git_pull()
  print("Pulling")
  vim.cmd("Git pull")
end

local function git_reset_head(opts)
  local num_commits = opts.args
  if num_commits == "" then
    vim.fn.inputsave()
    num_commits = vim.fn.input("# commits reset: ")
    vim.fn.inputrestore()
  end

  if num_commits == "" then
    return
  end

  vim.cmd.Git({ args = { "reset", "HEAD~" .. num_commits } })
end

vim.api.nvim_create_user_command("Gcommit", git_commit, { desc = "Commit with message in floaterm" })
vim.api.nvim_create_user_command("Grefresh", git_refresh, { desc = "Refresh gitsigns and Fugitive" })
vim.api.nvim_create_user_command("Gpush", git_push_current_branch, { desc = "Push current branch" })
vim.api.nvim_create_user_command("Gpull", git_pull, { desc = "Pull current branch" })
vim.api.nvim_create_user_command("Grh", git_reset_head, {
  nargs = "?",
  desc = "Reset HEAD by commit count",
})

vim.keymap.set("n", "<Leader>gg", "<Cmd>G<CR>", { silent = true, desc = "Summary" })
vim.keymap.set("n", "<Leader>gS", "<Cmd>G<CR>", { silent = true, desc = "Summary" })
vim.keymap.set("n", "<Leader>gr", "<Cmd>Grefresh<CR>", { silent = true, desc = "Refresh" })
vim.keymap.set("n", "<Leader>gR", "<Cmd>Grh<CR>", { silent = true, desc = "Reset" })
vim.keymap.set("n", "<Leader>gC", "<Cmd>Git commit<CR>", { silent = true, desc = "Commit" })
vim.keymap.set("n", "<Leader>gP", "<Cmd>Gpush<CR>", { silent = true, desc = "Push" })
vim.keymap.set("n", "<Leader>gL", "<Cmd>Gpull<CR>", { silent = true, desc = "Pull" })
vim.keymap.set("n", "<Leader>ga", "<Cmd>Gwrite<CR>", { silent = true, desc = "Add current file" })
vim.keymap.set("n", "<Leader>gU", "<Cmd>Git reset %<CR>", { silent = true, desc = "Undo current file" })
vim.keymap.set("n", "<Leader>gA", "<Cmd>Git add .<CR>", { silent = true, desc = "Add all" })
vim.keymap.set("n", "<Leader>gD", "<Cmd>Git diff<CR>", { silent = true, desc = "Global diff" })
vim.keymap.set("n", "<Leader>gB", "<Cmd>Git blame<CR>", { silent = true, desc = "Blame" })
vim.keymap.set("n", "<Leader>gl", "<Cmd>Gclog -50<CR>", { silent = true, desc = "Log" })

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("config.git.fugitive_reload", { clear = true }),
  callback = function(args)
    local filetype = vim.bo[args.buf].filetype
    if filetype == "fugitive" or filetype == "fugitiveblame" then
      reload_fugitive_status()
    end
  end,
})
