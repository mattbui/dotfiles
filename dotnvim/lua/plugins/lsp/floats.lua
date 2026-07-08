local M = {}

local close_events = { "CursorMoved", "CursorMovedI", "InsertCharPre", "ModeChanged", "BufHidden" }
local diagnostic_float_win
local suppressed_diagnostic_hover_range

local function has_lsp_floating_preview(bufnr)
  local ok, win = pcall(vim.api.nvim_buf_get_var, bufnr, "lsp_floating_preview")
  return ok and vim.api.nvim_win_is_valid(win)
end

local function get_lsp_floating_preview(bufnr)
  local ok, win = pcall(vim.api.nvim_buf_get_var, bufnr, "lsp_floating_preview")
  if ok and vim.api.nvim_win_is_valid(win) then
    return win
  end
end

local function diagnostic_range_at_cursor(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1] - 1
  local col = cursor[2]
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = lnum })

  for _, diagnostic in ipairs(diagnostics) do
    local start_lnum = diagnostic.lnum
    local start_col = diagnostic.col or 0
    local end_lnum = diagnostic.end_lnum or start_lnum
    local end_col = diagnostic.end_col or start_col + 1

    if
      (lnum > start_lnum or (lnum == start_lnum and col >= start_col))
      and (lnum < end_lnum or (lnum == end_lnum and col < end_col))
    then
      return {
        bufnr = bufnr,
        start_lnum = start_lnum,
        start_col = start_col,
        end_lnum = end_lnum,
        end_col = end_col,
      }
    end
  end
end

local function cursor_in_range(range)
  if not range or vim.api.nvim_get_current_buf() ~= range.bufnr then
    return false
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1] - 1
  local col = cursor[2]

  return (lnum > range.start_lnum or (lnum == range.start_lnum and col >= range.start_col))
    and (lnum < range.end_lnum or (lnum == range.end_lnum and col < range.end_col))
end

local function track_diagnostic_float(win)
  if not win then
    return
  end

  diagnostic_float_win = win
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      if diagnostic_float_win == win then
        diagnostic_float_win = nil
      end
    end,
  })
end

function M.jump_to_float()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = get_lsp_floating_preview(bufnr)
  if win then
    vim.api.nvim_set_current_win(win)
    return true
  end

  for _, float_win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(float_win)
    if config.relative ~= "" and config.focusable ~= false then
      vim.api.nvim_set_current_win(float_win)
      return true
    end
  end

  return false
end

function M.open_diagnostic()
  local _, win = vim.diagnostic.open_float({
    close_events = close_events,
    focusable = false,
    scope = "cursor",
  })
  track_diagnostic_float(win)
end

function M.open_diagnostic_on_hold()
  if vim.api.nvim_get_mode().mode ~= "n" then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if has_lsp_floating_preview(bufnr) then
    return
  end
  if cursor_in_range(suppressed_diagnostic_hover_range) then
    return
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = lnum })
  if vim.tbl_isempty(diagnostics) then
    return
  end

  local _, win = vim.diagnostic.open_float({
    close_events = close_events,
    focusable = false,
    scope = "cursor",
  })
  track_diagnostic_float(win)
end

function M.show_documentation()
  local filetype = vim.bo.filetype
  if filetype == "vim" or filetype == "help" then
    vim.cmd("help " .. vim.fn.expand("<cword>"))
    return
  end

  vim.lsp.buf.hover({
    border = "single",
    close_events = close_events,
    focusable = false,
  })
end

function M.jump_or_hover()
  if M.jump_to_float() then
    return
  end

  M.show_documentation()
end

function M.close_current_or_fallback(key)
  local win = vim.api.nvim_get_current_win()
  local config = vim.api.nvim_win_get_config(win)

  if config.relative ~= "" then
    vim.cmd.close()
    return
  end

  if key == "<Esc>" then
    vim.cmd.nohlsearch()
    return
  end

  vim.api.nvim_feedkeys(key, "n", false)
end

function M.escape()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = get_lsp_floating_preview(bufnr)

  if win then
    if diagnostic_float_win == win then
      suppressed_diagnostic_hover_range = diagnostic_range_at_cursor(bufnr)
      diagnostic_float_win = nil
    end

    pcall(vim.api.nvim_win_close, win, false)
    return
  end

  vim.cmd.nohlsearch()
end

function M.reset_diagnostic_hover_suppression()
  if not cursor_in_range(suppressed_diagnostic_hover_range) then
    suppressed_diagnostic_hover_range = nil
  end
end

return M
