-- Shows UI2's native showcmd events and macro recording keys in one float.
-- UI2 must be enabled first so its message and cmdline handlers can be wrapped.

local api = vim.api

local M = {}
local group = api.nvim_create_augroup("float_keys", { clear = true })
local recording_key_ns = api.nvim_create_namespace("float_keys_recording")
local escape_text = "^["

local state = {
  config = {
    timeout = 200,
    repeat_interval = 50,
    recording = {
      enabled = true,
      ignore_mouse = true,
      max_keys = 256,
      max_width = 60,
    },
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

  recording = {
    register = "",
    keys = {},
    truncated = false,
  },

  view = {
    buffer = nil,
    window = nil,
    text = "",
    render_scheduled = false,
    render_token = 0,
  },
}
local view = state.view

local function recording_active()
  return state.recording.register ~= ""
end

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

-- Recording input is rendered on the next main-loop tick. In particular, this
-- lets RecordingLeave clear the terminating q before it can be painted.
local function schedule_display_text(text)
  view.text = text
  schedule_float_render()
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
    if token ~= state.hide_token or state.active_text ~= "" or recording_active() then
      return
    end

    reset_repeat_state()
    update_display_text("")
  end, state.config.timeout)
end

local function reset_showcmd_state()
  invalidate_hide_timer()
  state.active_text = ""
  reset_repeat_state()
end

local function dismiss_float()
  reset_showcmd_state()

  -- Invalidate delayed rendering even if the float is already clear.
  view.text = ""
  render_float_now()
end

local function is_mouse_key(key)
  return key:find("Mouse", 1, true)
      or key:find("Scroll", 1, true)
      or key:find("Drag", 1, true)
      or key:find("Release", 1, true)
end

local function recording_display_width()
  local configured = state.config.recording.max_width
  local available = math.max(1, vim.o.columns - 4)
  return math.max(1, math.min(configured, available))
end

local function format_recording_display()
  local prefix = "recording@" .. state.recording.register .. ": "
  local max_width = recording_display_width()
  local prefix_width = vim.fn.strdisplaywidth(prefix)

  -- This only matters for an unusually narrow UI. The recording register and
  -- separator are ASCII, so character and display widths are equivalent here.
  if prefix_width >= max_width then
    return vim.fn.strcharpart(prefix, 0, max_width)
  end

  local key_width = 0
  local first = #state.recording.keys + 1
  local budget = max_width - prefix_width
  for index = #state.recording.keys, 1, -1 do
    local width = vim.fn.strdisplaywidth(state.recording.keys[index])
    if key_width + width > budget then
      break
    end

    key_width = key_width + width
    first = index
  end

  local truncated = state.recording.truncated or first > 1
  if truncated then
    local ellipsis_width = vim.fn.strdisplaywidth("…")
    while first <= #state.recording.keys and key_width + ellipsis_width > budget do
      key_width = key_width - vim.fn.strdisplaywidth(state.recording.keys[first])
      first = first + 1
    end
  end

  local keys = first <= #state.recording.keys
      and table.concat(state.recording.keys, "", first)
      or ""
  return prefix .. (truncated and "…" or "") .. keys
end

local function on_recording_key(_, typed)
  if not recording_active() or typed == "" then
    return
  end

  local key = vim.fn.keytrans(typed)
  if key == "" or (state.config.recording.ignore_mouse and is_mouse_key(key)) then
    return
  end

  state.recording.keys[#state.recording.keys + 1] = key
  if #state.recording.keys > state.config.recording.max_keys then
    table.remove(state.recording.keys, 1)
    state.recording.truncated = true
  end

  schedule_display_text(format_recording_display())
end

local function start_recording()
  if not state.config.recording.enabled then
    return
  end

  local register = vim.fn.reg_recording()
  if register == "" then
    return
  end

  reset_showcmd_state()
  state.recording.register = register
  state.recording.keys = {}
  state.recording.truncated = false

  vim.on_key(nil, recording_key_ns)
  vim.on_key(on_recording_key, recording_key_ns)

  -- Override a potentially delayed showcmd render with the recording header.
  view.render_token = view.render_token + 1
  view.render_scheduled = false
  schedule_display_text(format_recording_display())
end

local function stop_recording()
  vim.on_key(nil, recording_key_ns)
  if not recording_active() then
    return
  end

  state.recording.register = ""
  state.recording.keys = {}
  state.recording.truncated = false
  dismiss_float()
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
  -- Recording exclusively owns the float until RecordingLeave. This also
  -- prevents Escape's showcmd event from dismissing the recording display.
  if recording_active() then
    return
  end

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

    if target ~= "msg" and not recording_active() then
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

  api.nvim_create_autocmd("RecordingEnter", {
    group = group,
    callback = start_recording,
  })

  api.nvim_create_autocmd("RecordingLeave", {
    group = group,
    callback = stop_recording,
  })

  api.nvim_create_autocmd({ "TabEnter", "VimResized" }, {
    group = group,
    callback = function()
      if recording_active() then
        schedule_display_text(format_recording_display())
      else
        schedule_float_render()
      end
    end,
  })

  state.initialized = true
end

return M
