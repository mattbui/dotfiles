-- Tracks normal file buffers as preview or permanent buffers.
--
-- New file buffers start as previews. Editing or toggling a buffer promotes it
-- to permanent. Cleanup hides old previews and excess permanent buffers, and
-- closes known file buffers whose files were deleted.

local api = vim.api

local autocmds = api.nvim_create_augroup("dotfiles_buffers", { clear = true })

local max_preview_batches = 2
local max_permanent_buffers = 5

local preview_buffers = {}
local preview_batches = {}
local permanent_buffers = {}
local known_file_buffers = {}
local recency = {}
local recency_tick = 0
local preview_batch_id = 0
local active_preview_batch = nil
local startup_complete = false
local cleanup_pending = false

local function is_valid_buffer(bufnr)
  return api.nvim_buf_is_valid(bufnr)
end

local function buffer_name(bufnr)
  return api.nvim_buf_get_name(bufnr)
end

local function is_normal_file_buffer(bufnr)
  return is_valid_buffer(bufnr) and vim.bo[bufnr].buftype == "" and buffer_name(bufnr) ~= ""
end

local function is_visible(bufnr)
  return #vim.fn.win_findbuf(bufnr) > 0
end

local function can_close(bufnr)
  return is_normal_file_buffer(bufnr) and not vim.bo[bufnr].modified and not is_visible(bufnr)
end

local function can_unlist(bufnr)
  return can_close(bufnr) and api.nvim_buf_is_loaded(bufnr)
end

local function mark_known_file(bufnr)
  if is_normal_file_buffer(bufnr) and vim.uv.fs_stat(buffer_name(bufnr)) then
    known_file_buffers[bufnr] = true
  end
end

local function update_recency(bufnr)
  if not is_normal_file_buffer(bufnr) then
    return
  end

  if recency[bufnr] == recency_tick then
    return
  end

  recency_tick = recency_tick + 1
  recency[bufnr] = recency_tick
end

local function set_barbar_pinned(bufnr, pinned)
  local ok_state, state = pcall(require, "barbar.state")
  local ok_render, render = pcall(require, "barbar.ui.render")
  if not ok_state or not ok_render then
    return
  end

  local ok_pinned, is_pinned = pcall(state.is_pinned, bufnr)
  if not ok_pinned or is_pinned == pinned then
    return
  end

  state.toggle_pin(bufnr)
  render.update()
end

local function current_preview_batch()
  if not active_preview_batch then
    preview_batch_id = preview_batch_id + 1
    active_preview_batch = preview_batch_id
  end

  return active_preview_batch
end

local function mark_preview(bufnr)
  if not is_normal_file_buffer(bufnr) or permanent_buffers[bufnr] then
    return
  end

  if preview_buffers[bufnr] then
    return
  end

  preview_buffers[bufnr] = true
  preview_batches[bufnr] = current_preview_batch()
  set_barbar_pinned(bufnr, false)
end

local function mark_startup_buffers_permanent()
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if is_normal_file_buffer(bufnr) then
      preview_buffers[bufnr] = nil
      preview_batches[bufnr] = nil
      permanent_buffers[bufnr] = true
      update_recency(bufnr)
      mark_known_file(bufnr)
      set_barbar_pinned(bufnr, true)
    end
  end

  startup_complete = true
  active_preview_batch = nil
end

local function forget_buffer_state(bufnr)
  preview_buffers[bufnr] = nil
  preview_batches[bufnr] = nil
  permanent_buffers[bufnr] = nil
  recency[bufnr] = nil
  set_barbar_pinned(bufnr, false)
end

local function forget_buffer(bufnr)
  forget_buffer_state(bufnr)
  known_file_buffers[bufnr] = nil
end

local function delete_buffer(bufnr, opts)
  local ok = pcall(api.nvim_buf_delete, bufnr, opts or {})
  if ok or not api.nvim_buf_is_valid(bufnr) then
    forget_buffer(bufnr)
  end
end

local function unlist_buffer(bufnr)
  if not is_valid_buffer(bufnr) then
    forget_buffer(bufnr)
    return
  end

  forget_buffer_state(bufnr)

  pcall(function()
    vim.bo[bufnr].buflisted = false
  end)
end

local function list_buffer(bufnr)
  if is_normal_file_buffer(bufnr) then
    pcall(function()
      vim.bo[bufnr].buflisted = true
    end)
  end
end

local function cleanup_missing_file_buffers()
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if
        known_file_buffers[bufnr]
        and is_normal_file_buffer(bufnr)
        and not vim.bo[bufnr].modified
        and not vim.uv.fs_stat(buffer_name(bufnr))
    then
      delete_buffer(bufnr, { force = true })
    end
  end
end

local function sorted_buffers(buffers)
  table.sort(buffers, function(a, b)
    return (recency[a] or 0) < (recency[b] or 0)
  end)

  return buffers
end

local function cleanup_preview_batches()
  local previews = {}
  local batches = {}

  for bufnr in pairs(preview_buffers) do
    if is_normal_file_buffer(bufnr) then
      table.insert(previews, bufnr)
      batches[preview_batches[bufnr] or 0] = true
    else
      preview_buffers[bufnr] = nil
      preview_batches[bufnr] = nil
    end
  end

  local sorted_batches = vim.tbl_keys(batches)
  table.sort(sorted_batches)

  local overflow = #sorted_batches - max_preview_batches
  if overflow <= 0 then
    return
  end

  local batches_to_close = {}
  for _, batch in ipairs(sorted_batches) do
    if overflow <= 0 then
      break
    end

    batches_to_close[batch] = true
    overflow = overflow - 1
  end

  for _, bufnr in ipairs(sorted_buffers(previews)) do
    if batches_to_close[preview_batches[bufnr] or 0] and can_unlist(bufnr) then
      unlist_buffer(bufnr)
    end
  end
end

local function enforce_permanent_limit()
  local permanents = {}

  for bufnr in pairs(permanent_buffers) do
    if is_normal_file_buffer(bufnr) then
      table.insert(permanents, bufnr)
    else
      permanent_buffers[bufnr] = nil
    end
  end

  local overflow = #permanents - max_permanent_buffers
  if overflow <= 0 then
    return
  end

  for _, bufnr in ipairs(sorted_buffers(permanents)) do
    if overflow <= 0 then
      return
    end

    if can_unlist(bufnr) then
      unlist_buffer(bufnr)
      overflow = overflow - 1
    end
  end
end

local function cleanup_buffers()
  if not startup_complete then
    return
  end

  cleanup_missing_file_buffers()
  cleanup_preview_batches()
  enforce_permanent_limit()
  active_preview_batch = nil
end

local function schedule_cleanup_buffers()
  if cleanup_pending then
    return
  end

  cleanup_pending = true
  vim.defer_fn(function()
    cleanup_pending = false
    cleanup_buffers()
  end, 100)
end

local function promote(bufnr)
  if not is_normal_file_buffer(bufnr) or permanent_buffers[bufnr] then
    return
  end

  preview_buffers[bufnr] = nil
  preview_batches[bufnr] = nil
  permanent_buffers[bufnr] = true
  update_recency(bufnr)
  set_barbar_pinned(bufnr, true)
  schedule_cleanup_buffers()
end

local function mark_current_preview()
  local bufnr = api.nvim_get_current_buf()
  if not is_normal_file_buffer(bufnr) then
    return
  end

  permanent_buffers[bufnr] = nil
  preview_buffers[bufnr] = true
  preview_batches[bufnr] = preview_batches[bufnr] or current_preview_batch()
  update_recency(bufnr)
  set_barbar_pinned(bufnr, false)
  schedule_cleanup_buffers()
end

local function hide_preview_buffers()
  for bufnr in pairs(preview_buffers) do
    if can_unlist(bufnr) then
      unlist_buffer(bufnr)
    end
  end
end

local function close_non_permanent_buffers()
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if is_normal_file_buffer(bufnr) and not permanent_buffers[bufnr] and not vim.bo[bufnr].modified then
      delete_buffer(bufnr)
    end
  end
end

local function buffer_state_label(bufnr)
  if permanent_buffers[bufnr] then
    return "permanent"
  end

  if preview_buffers[bufnr] then
    return "preview"
  end

  return "-"
end

local function print_buffer_state()
  local lines = {
    string.format(
      "autobuffers: max_preview_batches=%d max_permanent=%d recency_tick=%d startup_complete=%s",
      max_preview_batches,
      max_permanent_buffers,
      recency_tick,
      tostring(startup_complete)
    ),
  }

  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    local name = buffer_name(bufnr)
    table.insert(
      lines,
      string.format(
        "#%d state=%s recency=%s batch=%s current=%s visible=%s listed=%s loaded=%s modified=%s buftype=%s known=%s name=%s",
        bufnr,
        buffer_state_label(bufnr),
        tostring(recency[bufnr] or "-"),
        tostring(preview_batches[bufnr] or "-"),
        tostring(bufnr == api.nvim_get_current_buf()),
        tostring(is_visible(bufnr)),
        tostring(vim.bo[bufnr].buflisted),
        tostring(api.nvim_buf_is_loaded(bufnr)),
        tostring(vim.bo[bufnr].modified),
        vim.bo[bufnr].buftype ~= "" and vim.bo[bufnr].buftype or '""',
        tostring(known_file_buffers[bufnr] == true),
        name ~= "" and vim.fn.fnamemodify(name, ":~:.") or '""'
      )
    )
  end

  print(table.concat(lines, "\n"))
end

api.nvim_create_autocmd({ "BufAdd", "BufReadPost", "BufNewFile", "BufEnter" }, {
  group = autocmds,
  callback = function(event)
    list_buffer(event.buf)
    mark_known_file(event.buf)
    mark_preview(event.buf)
    update_recency(event.buf)
    schedule_cleanup_buffers()
  end,
})

api.nvim_create_autocmd("VimEnter", {
  group = autocmds,
  callback = function()
    vim.schedule(mark_startup_buffers_permanent)
  end,
})

api.nvim_create_autocmd({ "BufWritePost", "BufFilePost" }, {
  group = autocmds,
  callback = function(event)
    mark_known_file(event.buf)
  end,
})

api.nvim_create_autocmd("InsertEnter", {
  group = autocmds,
  callback = function()
    promote(api.nvim_get_current_buf())
  end,
})

api.nvim_create_autocmd("OptionSet", {
  group = autocmds,
  pattern = "modified",
  callback = function()
    local bufnr = api.nvim_get_current_buf()
    if is_valid_buffer(bufnr) and vim.bo[bufnr].modified then
      promote(bufnr)
    end
  end,
})

api.nvim_create_autocmd("TextChanged", {
  group = autocmds,
  callback = function(event)
    if is_valid_buffer(event.buf) and vim.bo[event.buf].modified then
      promote(event.buf)
    end
  end,
})

api.nvim_create_autocmd("FocusGained", {
  group = autocmds,
  callback = cleanup_missing_file_buffers,
})

api.nvim_create_autocmd("FileChangedShell", {
  group = autocmds,
  callback = function(event)
    if vim.v.fcs_reason ~= "deleted" then
      return
    end

    known_file_buffers[event.buf] = true
    vim.v.fcs_choice = ""
    vim.schedule(cleanup_missing_file_buffers)
  end,
})

api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = autocmds,
  callback = function(event)
    local bufnr = event.buf
    vim.schedule(function()
      if not api.nvim_buf_is_valid(bufnr) or not api.nvim_buf_is_loaded(bufnr) or not vim.bo[bufnr].buflisted then
        forget_buffer(bufnr)
      end
    end)
  end,
})

api.nvim_create_autocmd("VimLeavePre", {
  group = autocmds,
  callback = close_non_permanent_buffers,
})

local function create_user_command(name, callback)
  pcall(api.nvim_del_user_command, name)
  api.nvim_create_user_command(name, callback, {})
end

create_user_command("BufferPromote", function()
  promote(api.nvim_get_current_buf())
end)

create_user_command("BufferMarkPreview", mark_current_preview)

create_user_command("BufferTogglePermanent", function()
  local bufnr = api.nvim_get_current_buf()
  if permanent_buffers[bufnr] then
    mark_current_preview()
  else
    promote(bufnr)
  end
end)

pcall(api.nvim_del_user_command, "BufferClosePreviews")
create_user_command("BufferHidePreviews", hide_preview_buffers)

create_user_command("BufferState", print_buffer_state)

vim.keymap.set("n", "<Leader>P", "<Cmd>BufferTogglePermanent<CR>",
  { silent = true, desc = "Toggle permanent buffer" })
vim.keymap.set("n", "<Leader>bP", "<Cmd>BufferPromote<CR>", { silent = true, desc = "Mark permanent" })
vim.keymap.set("n", "<Leader>bm", "<Cmd>BufferMarkPreview<CR>", { silent = true, desc = "Mark preview" })
vim.keymap.set("n", "<Leader>bt", "<Cmd>BufferTogglePermanent<CR>", { silent = true, desc = "Toggle permanent" })
vim.keymap.set("n", "<Leader>bH", "<Cmd>BufferHidePreviews<CR>", { silent = true, desc = "Hide previews" })
vim.keymap.set("n", "<Leader>bS", "<Cmd>BufferState<CR>", { silent = true, desc = "Show state" })
