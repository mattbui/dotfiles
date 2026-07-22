--- Close dismissible windows (quickfix, help, and similar) before actually closing a normal window.
local api = vim.api

local dismissible_filetypes = {
  checkhealth = true,
  fugitive = true,
  fugitiveblame = true,
  git = true,
  help = true,
  man = true,
  qf = true,
  ["vim-pack-list"] = true,
}

local normal_state_var = "smart_quit_normal_state"

local function is_dismissible_buffer(bufnr)
  return api.nvim_buf_is_valid(bufnr) and dismissible_filetypes[vim.bo[bufnr].filetype] == true
end

local function is_dismissible_window(winid)
  return api.nvim_win_is_valid(winid) and is_dismissible_buffer(api.nvim_win_get_buf(winid))
end

local function is_floating(winid)
  return api.nvim_win_get_config(winid).relative ~= ""
end

local function window_in_tab(winid, tabpage)
  return api.nvim_win_is_valid(winid) and api.nvim_win_get_tabpage(winid) == tabpage
end

local function is_normal_base_window(winid, tabpage)
  return window_in_tab(winid, tabpage) and not is_floating(winid) and not is_dismissible_window(winid)
end

local function is_normal_buffer(bufnr)
  return api.nvim_buf_is_valid(bufnr)
      and api.nvim_buf_is_loaded(bufnr)
      and vim.bo[bufnr].buflisted
      and vim.bo[bufnr].buftype == ""
      and not is_dismissible_buffer(bufnr)
end

local function quit_or_confirm()
  local would_quit_neovim = not is_floating(api.nvim_get_current_win())
      and vim.fn.winnr("$") == 1
      and vim.fn.tabpagenr("$") == 1

  if not would_quit_neovim then
    vim.cmd.quit()
    return
  end

  vim.ui.select({ "yes", "no" }, {
    prompt = "Quit Neovim?",
    snacks = {
      layout = {
        preset = "select",
        hidden = { "input", "preview" },
        layout = { width = 40, min_width = 40 },
      },
    },
  }, function(choice)
    if choice == "yes" then
      vim.cmd.quit()
    end
  end)
end

local function remember_normal_window(winid)
  if not api.nvim_win_is_valid(winid) or is_floating(winid) then
    return
  end

  local bufnr = api.nvim_win_get_buf(winid)
  if not is_normal_buffer(bufnr) then
    return
  end

  api.nvim_tabpage_set_var(api.nvim_win_get_tabpage(winid), normal_state_var, {
    winid = winid,
    bufnr = bufnr,
    cursor = api.nvim_win_get_cursor(winid),
  })
end

local function get_normal_state(tabpage)
  local ok, state = pcall(api.nvim_tabpage_get_var, tabpage, normal_state_var)
  if not ok
      or type(state) ~= "table"
      or not is_normal_buffer(state.bufnr)
  then
    return
  end
  return state
end

local function restore_normal_state(winid, state)
  local bufnr = state and state.bufnr or api.nvim_create_buf(true, false)
  api.nvim_win_set_buf(winid, bufnr)

  if not state then
    return
  end

  local line_count = api.nvim_buf_line_count(bufnr)
  local line = math.min(state.cursor[1], line_count)
  local line_text = api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
  local column = math.min(state.cursor[2], #line_text)
  api.nvim_win_set_cursor(winid, { line, column })
end

local function find_anchor(tabpage, dismissible_windows, normal_windows)
  local current_win = api.nvim_get_current_win()
  if is_normal_base_window(current_win, tabpage) then
    return current_win
  end

  local state = get_normal_state(tabpage)
  if state and is_normal_base_window(state.winid, tabpage) then
    return state.winid
  end

  if normal_windows[1] then
    return normal_windows[1]
  end

  for _, winid in ipairs(dismissible_windows) do
    if not is_floating(winid) then
      restore_normal_state(winid, state)
      return winid
    end
  end
end

local function dismiss_windows(dismissible_windows, anchor)
  api.nvim_set_current_win(anchor)

  local errors = {}
  for _, dismissible_win in ipairs(dismissible_windows) do
    if api.nvim_win_is_valid(dismissible_win) and is_dismissible_window(dismissible_win) then
      local ok, err = pcall(api.nvim_win_close, dismissible_win, false)
      if not ok then
        errors[#errors + 1] = tostring(err)
      end
    end
  end

  if errors[1] then
    vim.notify(table.concat(errors, "\n"), vim.log.levels.ERROR)
  end
end

local function smart_quit()
  local tabpage = api.nvim_get_current_tabpage()
  local dismissible_windows = {}
  local normal_windows = {}

  for _, winid in ipairs(api.nvim_tabpage_list_wins(tabpage)) do
    if is_dismissible_window(winid) then
      dismissible_windows[#dismissible_windows + 1] = winid
    elseif not is_floating(winid) then
      normal_windows[#normal_windows + 1] = winid
    end
  end

  if #dismissible_windows == 0 then
    quit_or_confirm()
    return
  end

  local anchor = find_anchor(tabpage, dismissible_windows, normal_windows)
  if not anchor then
    vim.cmd.quit()
    return
  end

  dismiss_windows(dismissible_windows, anchor)
end

local group = api.nvim_create_augroup("config.smart_quit", { clear = true })

api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
  group = group,
  desc = "Remember the last normal buffer in each tab",
  callback = function()
    remember_normal_window(api.nvim_get_current_win())
  end,
})

remember_normal_window(api.nvim_get_current_win())

api.nvim_create_user_command("SmartQuit", smart_quit, {
  desc = "Close dismissible windows, or quit the current window",
})
