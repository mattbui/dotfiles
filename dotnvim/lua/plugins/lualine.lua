pcall(vim.cmd.packadd, "lualine.nvim")

local ok, lualine = pcall(require, "lualine")
if not ok then
  vim.schedule(function()
    vim.notify("lualine.nvim is not available; run vim.pack update/repair", vim.log.levels.WARN)
  end)
  return
end

local function paste()
  local ok_paste, is_paste = pcall(function()
    return vim.o.paste
  end)

  return ok_paste and is_paste and "PASTE" or ""
end

local function truncate_display(value, max_width, side)
  value = value or ""
  if value == "" or vim.fn.strdisplaywidth(value) <= max_width then
    return value
  end

  local ellipsis = "…"
  local target_width = max_width - vim.fn.strdisplaywidth(ellipsis)
  if target_width <= 0 then
    return ellipsis
  end

  local result = ""

  if side == "left" then
    for i = vim.fn.strchars(value) - 1, 0, -1 do
      local next_result = vim.fn.strcharpart(value, i, 1) .. result
      if vim.fn.strdisplaywidth(next_result) > target_width then
        break
      end
      result = next_result
    end

    return ellipsis .. result
  end

  for i = 0, vim.fn.strchars(value) - 1 do
    local next_result = result .. vim.fn.strcharpart(value, i, 1)
    if vim.fn.strdisplaywidth(next_result) > target_width then
      break
    end
    result = next_result
  end

  return result .. ellipsis
end

local function truncate(width, side, opts)
  opts = opts or {}

  return function(value)
    value = value or ""
    local prefix = opts.preserve_prefix and value:match("^%S+%s+") or ""
    local prefix_width = vim.fn.strdisplaywidth(prefix)
    if prefix_width >= width then
      return truncate_display(prefix, width)
    end

    return prefix .. truncate_display(value:sub(#prefix + 1), width - prefix_width, side)
  end
end

local function should_hide_path()
  local hidden_filetypes = {
    "fff_input",
    "fff_list",
    "fff_preview",
    "fff_file_info",
    "floaterm",
    "git",
    "fugitive",
    "qf",
    "snacks_picker_input",
    "snacks_picker_list",
    "snacks_picker_preview",
    "yazi"
  }

  if vim.tbl_contains(hidden_filetypes, vim.bo.filetype) then
    return true
  end

  return vim.bo.buftype == "nofile" and vim.api.nvim_buf_get_name(0):match("/?fffiles? ") ~= nil
end

local function smart_path()
  if should_hide_path() then
    return ""
  end

  local path = vim.fn.expand("%:.")
  if path == "" then
    path = "[No Name]"
  end

  local max_path_width = 50
  local shorten_threshold = math.min(max_path_width, math.max(40, math.floor(vim.api.nvim_win_get_width(0) * 0.3)))
  if vim.fn.strdisplaywidth(path) > shorten_threshold then
    local parts = vim.split(path, "/", { plain = true })
    if #parts > 1 then
      local parent_lengths = { 6, 3, 2, 1 }
      local shortened = {}
      for i = 1, #parts - 1 do
        local distance_from_file = #parts - i
        local length_index = math.min(distance_from_file, #parent_lengths)
        table.insert(shortened, vim.fn.strcharpart(parts[i], 0, parent_lengths[length_index]))
      end
      table.insert(shortened, parts[#parts])
      path = table.concat(shortened, "/")
    end
  end

  path = truncate_display(path, max_path_width, "left")

  local prefix = vim.bo.filetype ~= "help" and vim.bo.readonly and " " or ""
  local suffix = vim.bo.modifiable and vim.bo.modified and " ●" or ""
  local path_width = max_path_width - vim.fn.strdisplaywidth(prefix) - vim.fn.strdisplaywidth(suffix)

  return prefix .. truncate_display(path, path_width, "left") .. suffix
end

local function conform_formatters()
  local ok_conform, conform = pcall(require, "conform")
  if not ok_conform then
    return ""
  end

  local format_on_save = ""
  local ok_autoformat, autoformat = pcall(require, "plugins.autoformat")
  if ok_autoformat and autoformat.format_on_save then
    format_on_save = " 󰁨"
  end

  local formatters = conform.list_formatters_for_buffer(0)
  if #formatters > 0 then
    return "󰷈 " .. table.concat(formatters, " ") .. format_on_save
  end

  local ok_lsp_format, lsp_format = pcall(require, "conform.lsp_format")
  if not ok_lsp_format then
    return ""
  end

  local lsp_clients = lsp_format.get_format_clients({ bufnr = vim.api.nvim_get_current_buf() })
  if vim.tbl_isempty(lsp_clients) then
    return ""
  end

  return "󰷈 lsp" .. format_on_save
end

local lualine_theme = require("lualine.themes.tokyonight-storm")
local diagnostics = require("plugins.lsp.diagnostics")
local symbols = require("plugins.lsp.symbols")

for _, mode in ipairs({ "insert", "visual", "replace", "command", "terminal", "inactive" }) do
  if lualine_theme[mode] ~= nil then
    lualine_theme[mode].b = lualine_theme.normal.b
  end
end

lualine.setup({
  options = {
    theme = lualine_theme,
    globalstatus = true,
    component_separators = "|",
    section_separators = "",
  },
  sections = {
    lualine_a = { "mode", paste },
    lualine_b = {
      {
        "branch",
        icon = "",
        fmt = truncate(24, "right"),
      },
      smart_path,
    },
    lualine_c = {
      {
        symbols.current_display,
        fmt = truncate(40, "left", { preserve_prefix = true }),
      },
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = diagnostics.symbols,
      },
    },
    lualine_x = {
      {
        "lsp_status",
        fmt = vim.trim,
        symbols = { done = "", },
      },

      conform_formatters,
    },
    lualine_y = {
      { "filetype", colored = false, },
      { "progress", fmt = vim.trim, },
    },
    lualine_z = {
      { "location", fmt = vim.trim, },
    },
  },
})
