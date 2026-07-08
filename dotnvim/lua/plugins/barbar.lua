local api = vim.api
local map = vim.keymap.set
local silent = { silent = true }
local M = {}
local preview_button = "◌"
local close_button = "✕"
local pinned_icons_patched = false

-- Copies one barbar highlight group into another and toggles italic.
local function style_like(group, target, italic)
  local ok, attrs = pcall(api.nvim_get_hl, 0, { name = target, link = false })
  if not ok then
    attrs = {}
  end

  local highlight = vim.deepcopy(attrs)
  ---@cast highlight vim.api.keyset.highlight
  highlight.link = nil
  highlight.cterm = nil
  highlight.default = nil
  if italic then
    highlight.italic = true
  else
    highlight.italic = nil
  end

  api.nvim_set_hl(0, group, highlight)
end

-- Applies autobuffer tab styling: preview groups are italic, while pinned and
-- modified groups copy the same colors with italic disabled.
function M.apply_highlights()
  for _, activity in ipairs({ "Current", "Visible", "Inactive", "Alternate" }) do
    local base = "Buffer" .. activity
    local pin = base .. "Pin"

    style_like(base, base, true)
    style_like(pin, base, false)
    style_like(pin .. "Btn", pin, false)
    style_like(base .. "Mod", pin, false)
    style_like(base .. "ModBtn", pin .. "Btn", false)
  end
end

-- Barbar hides the filename/button behind pinned icon settings. This patch
-- keeps pinned buffers' button as close/modified while still using barbar's
-- pinned state for ordering.
local function patch_pinned_icons()
  local ok_buffer, buffer = pcall(require, "barbar.buffer")
  local ok_config, config = pcall(require, "barbar.config")
  if not ok_buffer or not ok_config or pinned_icons_patched then
    return
  end

  local get_icons = buffer.get_icons
  buffer.get_icons = function(activity, modified, pinned)
    local icons = get_icons(activity, modified, pinned)
    if not pinned then
      return icons
    end

    local activity_icons = config.options.icons[activity:lower()]
    if not activity_icons then
      return icons
    end

    local patched = vim.tbl_deep_extend("force", {}, icons)
    patched.filename = true
    patched.button = modified and activity_icons.modified.button or close_button
    return patched
  end

  pinned_icons_patched = true
end

map("n", "<S-k>", "<Cmd>BufferPrevious<CR>", silent)
map("n", "<S-j>", "<Cmd>BufferNext<CR>", silent)
map("n", "<S-l>", "<Cmd>BufferMoveNext<CR>", silent)
map("n", "<S-h>", "<Cmd>BufferMovePrevious<CR>", silent)
map("n", "<C-w>", "<Cmd>BufferClose<CR>", silent)

for i = 1, 9 do
  map("n", "<Leader>" .. i, "<Cmd>BufferGoto " .. i .. "<CR>", silent)
end

map("n", "<Leader>0", "<Cmd>BufferLast<CR>", silent)
map("n", "<Leader>p", "<Cmd>BufferPick<CR>", silent)

require("barbar").setup({
  tabpages = false,

  icons = {
    button = preview_button,
    scroll = {
      left = "",
      right = "",
    },

    filetype = {
      custom_colors = true,
    },

    gitsigns = {
      added = { enabled = true, icon = "+" },
      changed = { enabled = true, icon = "~" },
      deleted = { enabled = true, icon = "-" },
    },

    pinned = {
      button = false,
      filename = true,
    },

    separator = {
      left = "▎",
    },
  },

  maximum_padding = 2,
  minimum_padding = 2,
  no_name_title = "unnamed",
})

patch_pinned_icons()

return M
