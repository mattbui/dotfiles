local reload_fugitive = false

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
  reload_fugitive = true
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

local function git_change_branch()
  vim.fn.inputsave()
  local branch = vim.fn.input("Change to branch: ")
  vim.fn.inputrestore()

  if branch == "" then
    return
  end

  vim.cmd.redraw()
  vim.cmd.Git({ args = { "checkout", branch } })
end

local function git_new_branch()
  vim.fn.inputsave()
  local new_branch = vim.fn.input("Create new branch: ")
  vim.fn.inputrestore()

  if new_branch == "" then
    return
  end

  vim.fn.inputsave()
  local old_branch = vim.fn.input("From old branch: ")
  vim.fn.inputrestore()

  if old_branch == "" then
    old_branch = fugitive_head()
  end

  vim.cmd.redraw()
  if old_branch == "" then
    vim.cmd.Git({ args = { "checkout", "-b", new_branch } })
  else
    vim.cmd.Git({ args = { "checkout", "-b", new_branch, old_branch } })
  end
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
vim.api.nvim_create_user_command("Gchangebranch", git_change_branch, { desc = "Change Git branch" })
vim.api.nvim_create_user_command("Gnewbranch", git_new_branch, { desc = "Create Git branch" })
vim.api.nvim_create_user_command("Grh", git_reset_head, {
  nargs = "?",
  desc = "Reset HEAD by commit count",
})

vim.keymap.set("n", "<Leader>gco", git_change_branch, { silent = true, desc = "Change Git branch" })
vim.keymap.set("n", "<Leader>gcb", git_new_branch, { silent = true, desc = "Create Git branch" })

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("dotfiles_fugitive_reload", { clear = true }),
  callback = function()
    if not reload_fugitive then
      return
    end

    reload_fugitive_status()
    reload_fugitive = false
  end,
})
