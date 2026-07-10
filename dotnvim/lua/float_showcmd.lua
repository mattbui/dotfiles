-- Mirrors UI2's native showcmd events in a small floating window.
-- UI2 must be enabled first so its message and cmdline handlers can be wrapped.

local api = vim.api

local M = {}
local group = api.nvim_create_augroup("float_showcmd", { clear = true })
-- Reuse one hidden scratch buffer and float across updates.
local buffer
local window
local scheduled = false
local pending_text = ""
local subscribed = false
-- Avoid flashing the float for basic cursor movement.
local skipped = {
  h = true,
  j = true,
  k = true,
  l = true,
  b = true,
  w = true,
}

local function hide()
  if window and api.nvim_win_is_valid(window) then
    pcall(api.nvim_win_set_config, window, { hide = true })
  end
end

local function ensure_buffer()
  if buffer and api.nvim_buf_is_valid(buffer) then
    return buffer
  end

  buffer = api.nvim_create_buf(false, true)
  vim.bo[buffer].bufhidden = "hide"
  vim.bo[buffer].swapfile = false

  return buffer
end

local function window_config(width)
  local target = api.nvim_get_current_win()

  -- Follow the global statusline as UI2 expands and collapses the cmdline.
  return {
    relative = "laststatus",
    anchor = "SW",
    row = 0,
    col = 0,
    width = width,
    height = 1,
    border = "single",
    style = "minimal",
    focusable = false,
    mouse = false,
    zindex = 60,
    hide = false,
    win = target,
  }
end

local function render()
  scheduled = false

  if pending_text == "" then
    hide()
    return
  end

  local display = " " .. pending_text .. " "
  local showcmd_buffer = ensure_buffer()
  api.nvim_buf_set_lines(showcmd_buffer, 0, -1, false, { display })

  local config = window_config(vim.fn.strdisplaywidth(display))
  if window and api.nvim_win_is_valid(window) then
    api.nvim_win_set_config(window, config)
    return
  end

  config.noautocmd = true
  window = api.nvim_open_win(showcmd_buffer, false, config)
  vim.wo[window].winblend = 0
end

local function schedule_render()
  if scheduled then
    return
  end

  scheduled = true
  vim.schedule(render)
end

local function showcmd_text(content)
  local parts = {}
  for _, chunk in ipairs(content or {}) do
    parts[#parts + 1] = chunk[2]
  end

  return table.concat(parts)
end

local function should_render(text)
  return skipped[text] ~= true
end

local function update(text)
  pending_text = text

  -- Pending commands can block, so render immediately whenever it is safe.
  if vim.in_fast_event() then
    schedule_render()
  else
    render()
  end
end

function M.setup()
  vim.opt.showcmd = true
  vim.opt.showcmdloc = "last"

  -- Extend UI2's native handlers while preserving their original behavior.
  if not subscribed then
    local messages = require("vim._core.ui2.messages")
    local cmdline = require("vim._core.ui2.cmdline")
    local original_showcmd = messages.msg_showcmd
    local original_cmdline_show = cmdline.cmdline_show
    local original_cmdline_hide = cmdline.cmdline_hide

    messages.msg_showcmd = function(content)
      original_showcmd(content)
      local text = showcmd_text(content)
      if should_render(text) then
        update(text)
      end
    end

    -- Reposition after UI2 updates the command-line geometry.
    cmdline.cmdline_show = function(...)
      original_cmdline_show(...)
      render()
    end

    cmdline.cmdline_hide = function(...)
      original_cmdline_hide(...)
      render()
    end

    subscribed = true
  end

  api.nvim_create_autocmd({ "TabEnter", "VimResized" }, {
    group = group,
    callback = schedule_render,
  })
end

return M
