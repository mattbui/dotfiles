-- Mirrors UI2's native showcmd events in a small floating window.
-- UI2 must be enabled first so its message and cmdline handlers can be wrapped.

local api = vim.api

local M = {}
local group = api.nvim_create_augroup("float_showcmd", { clear = true })
local escape_text = "^["

local state = {
  config = {
    timeout = 200,
    repeat_interval = 50,
    window = {
      relative = "laststatus",
      anchor = "SW",
      row = 0,
      col = 0,
      height = 1,
      border = vim.o.winborder ~= "" and vim.o.winborder or "single",
      style = "minimal",
      focusable = false,
      mouse = false,
      zindex = 60,
    },
  },

  initialized = false,
  active_text = "",
  last_completed = {
    text = "",
    completed_at = 0,
    count = 0,
  },
  hide_token = 0,

  view = {
    buffer = nil,
    window = nil,
    text = "",
    render_scheduled = false,
    render_token = 0,
  },
}
local view = state.view

local function now_ms()
  return vim.uv.hrtime() / 1e6
end

local function hide_float()
  if view.window and api.nvim_win_is_valid(view.window) then
    pcall(api.nvim_win_set_config, view.window, { hide = true })
  end
end

---@return integer
local function ensure_float_buffer()
  if view.buffer and api.nvim_buf_is_valid(view.buffer) then
    return view.buffer
  end

  local buffer = api.nvim_create_buf(false, true)
  view.buffer = buffer
  vim.bo[buffer].bufhidden = "hide"
  vim.bo[buffer].swapfile = false

  return buffer
end

local function make_float_window_config(width)
  -- Follow the global statusline as UI2 expands and collapses the cmdline.
  return vim.tbl_extend("force", state.config.window, {
    width = width,
    hide = false,
    win = api.nvim_get_current_win(),
  })
end

local function render_float()
  view.render_scheduled = false

  if view.text == "" then
    hide_float()
    return
  end

  local display = " " .. view.text .. " "
  local buffer = ensure_float_buffer()
  api.nvim_buf_set_lines(buffer, 0, -1, false, { display })

  local win_config = make_float_window_config(vim.fn.strdisplaywidth(display))
  if view.window and api.nvim_win_is_valid(view.window) then
    api.nvim_win_set_config(view.window, win_config)
    return
  end

  win_config.noautocmd = true
  local window = api.nvim_open_win(buffer, false, win_config)
  view.window = window
  vim.wo[window].winblend = 0
end

local function schedule_float_render(delay)
  if view.render_scheduled then
    return
  end

  view.render_scheduled = true
  view.render_token = view.render_token + 1
  local token = view.render_token
  local render_callback = function()
    if token == view.render_token then
      render_float()
    end
  end

  if delay and delay > 0 then
    vim.defer_fn(render_callback, math.ceil(delay))
  else
    vim.schedule(render_callback)
  end
end

local function render_float_now()
  -- Invalidate a delayed repeat render before painting newer state.
  view.render_token = view.render_token + 1
  view.render_scheduled = false

  if vim.in_fast_event() then
    schedule_float_render()
  else
    render_float()
  end
end

local function update_display_text(text, delay)
  if text == view.text then
    return
  end

  view.text = text
  if delay and delay > 0 then
    schedule_float_render(delay)
  else
    render_float_now()
  end
end

local function reset_repeat_state()
  state.last_completed.text = ""
  state.last_completed.completed_at = 0
  state.last_completed.count = 0
end

local function is_repeat_candidate(text, timestamp)
  return text == state.last_completed.text
      and timestamp - state.last_completed.completed_at <= state.config.timeout
end

local function format_repeat_display(text, count)
  return count > 1 and (text .. "×" .. count) or text
end

local function invalidate_hide_timer()
  state.hide_token = state.hide_token + 1
end

local function schedule_float_hide()
  invalidate_hide_timer()
  local token = state.hide_token

  vim.defer_fn(function()
    if token ~= state.hide_token or state.active_text ~= "" then
      return
    end

    reset_repeat_state()
    update_display_text("")
  end, state.config.timeout)
end

local function dismiss_float()
  invalidate_hide_timer()
  state.active_text = ""
  reset_repeat_state()

  -- Invalidate delayed rendering even if the float is already clear.
  view.text = ""
  render_float_now()
end

-- Escape cancels the current interaction and hides the float immediately.
local function on_escape()
  dismiss_float()
end

-- Non-empty text starts or updates the current showcmd interaction.
local function on_text(text)
  invalidate_hide_timer()
  state.active_text = text

  -- Matching text is only a repeat candidate. Neovim can also re-emit mapping
  -- prefixes (the event sequence "y", "", "y"), so wait for the next clear event.
  if is_repeat_candidate(text, now_ms()) then
    return
  end

  update_display_text(text)
end

-- Empty msg (clear) finalizes the active text and starts its hide timeout.
local function on_clear()
  if state.active_text == "" then
    return
  end

  -- A text event can't be considered as a repeat candidate or completed until it's followed by a clear event
  local timestamp = now_ms()
  local repeated = is_repeat_candidate(state.active_text, timestamp)
  state.last_completed.count = repeated and state.last_completed.count + 1 or 1
  state.last_completed.text = state.active_text
  state.last_completed.completed_at = timestamp
  state.active_text = ""

  local display = format_repeat_display(state.last_completed.text, state.last_completed.count)
  local delay = repeated and state.config.repeat_interval or nil
  update_display_text(display, delay)
  schedule_float_hide()
end

local function extract_showcmd_text(content)
  local parts = {}
  for _, chunk in ipairs(content or {}) do
    parts[#parts + 1] = chunk[2]
  end
  return table.concat(parts)
end

local function dispatch_showcmd_event(content)
  local text = extract_showcmd_text(content)

  -- showcmd renders Escape (and its Ctrl-[ equivalent) as a trailing ^[.
  if text:sub(- #escape_text) == escape_text then
    on_escape()
  elseif text == "" then
    on_clear()
  else
    on_text(text)
  end
end

local function patch_ui2_showcmd()
  local messages = require("vim._core.ui2.messages")
  local ui2_showcmd = messages.msg_showcmd

  messages.msg_showcmd = function(content)
    ui2_showcmd(content)
    dispatch_showcmd_event(content)
  end
end

local function patch_ui2_show_msg()
  local messages = require("vim._core.ui2.messages")
  local ui2_show_msg = messages.show_msg

  messages.show_msg = function(target, ...)
    ui2_show_msg(target, ...)

    if target ~= "msg" then
      dismiss_float()
    end
  end
end

local function patch_ui2_cmdline()
  local cmdline = require("vim._core.ui2.cmdline")
  local ui2_cmdline_show = cmdline.cmdline_show
  local ui2_cmdline_hide = cmdline.cmdline_hide

  -- Reposition after UI2 updates the command-line geometry.
  cmdline.cmdline_show = function(...)
    ui2_cmdline_show(...)
    render_float_now()
  end

  cmdline.cmdline_hide = function(...)
    ui2_cmdline_hide(...)
    render_float_now()
  end
end

function M.setup(opts)
  state.config = vim.tbl_deep_extend("force", state.config, opts or {})
  vim.opt.showcmd = true
  vim.opt.showcmdloc = "last"

  if state.initialized then
    return
  end

  patch_ui2_showcmd()
  patch_ui2_show_msg()
  patch_ui2_cmdline()

  api.nvim_create_autocmd({ "TabEnter", "VimResized" }, {
    group = group,
    callback = function()
      schedule_float_render()
    end,
  })

  state.initialized = true
end

return M
