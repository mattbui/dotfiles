local api = vim.api

if vim.fn.has("termguicolors") == 1 then
  vim.opt.termguicolors = true
end

local function hl(group, opts)
  api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
  hl(group, { link = target })
end

local function apply_tokyonight_storm()
  hl("BufferCurrentSign", { fg = "#bb9af7", ctermfg = 110 })
  hl("BufferCurrentTarget", { fg = "#bb9af7", ctermfg = 110 })
  hl("BufferCurrentADDED", { fg = "#73daca" })
  hl("BufferCurrentCHANGED", { fg = "#e0af68" })
  hl("BufferCurrentDELETED", { fg = "#f7768e" })
  hl("BufferScrollArrow", { fg = "#7dcfff", bg = "#292e42" })
  hl("BufferInactiveTarget", { fg = "#bb9af7", bg = "#3b4261", ctermfg = 110, ctermbg = 238 })
  hl("BufferVisibleTarget", { fg = "#bb9af7", bg = "#3b4261", ctermfg = 110, ctermbg = 240 })

  hl("BufferVisible", { fg = "#636a8d", bg = "#292e42" })
  hl("BufferVisibleADDED", { fg = "#73daca", bg = "#292e42" })
  hl("BufferVisibleCHANGED", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferVisibleDELETED", { fg = "#f7768e", bg = "#292e42" })
  hl("BufferVisibleINFO", { fg = "#0db9d7", bg = "#292e42" })
  hl("BufferVisibleWARN", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferVisibleERROR", { fg = "#db4b4b", bg = "#292e42" })
  hl("BufferVisibleSign", { fg = "#636a8d", bg = "#292e42" })

  hl("BufferInactive", { fg = "#636a8d", bg = "#292e42" })
  hl("BufferInactiveADDED", { fg = "#73daca", bg = "#292e42" })
  hl("BufferInactiveCHANGED", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferInactiveDELETED", { fg = "#f7768e", bg = "#292e42" })
  hl("BufferInactiveINFO", { fg = "#0db9d7", bg = "#292e42" })
  hl("BufferInactiveWARN", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferInactiveERROR", { fg = "#db4b4b", bg = "#292e42" })
  hl("BufferInactiveSign", { fg = "#292e42", bg = "#292e42" })

  hl("CursorLineNr", { fg = "#bb9af7" })
  hl("SignColumn", { fg = "#3b4261", bg = "#24283b" })
  hl("WinSeparator", { fg = "#3B4261", bold = true })

  hl("DiffAdd", { fg = "#73daca", bg = "#2c3a44" })
  hl("DiffChange", { fg = "#e0af68", bg = "#383545" })
  hl("DiffDelete", { fg = "#f7768e", bg = "#3a3044" })
  hl("DiffText", { fg = "#a9b1d6", bg = "#363b50" })

  hl("GitSignsAdd", { fg = "#5fb0a3", bg = "#24283b" })
  hl("GitSignsChange", { fg = "#9b7f4f", bg = "#24283b" })
  hl("GitSignsDelete", { fg = "#c26378", bg = "#24283b" })
  hl("GitSignsChangedelete", { fg = "#9b7f4f", bg = "#24283b" })
  hl("GitSignsTopdelete", { fg = "#c26378", bg = "#24283b" })
  hl("GitSignsUntracked", { fg = "#5fb0a3", bg = "#24283b" })

  hl("diffAdded", { fg = "#73daca", bg = "#2c3a44" })
  hl("diffChanged", { fg = "#e0af68", bg = "#383545" })
  hl("diffRemoved", { fg = "#f7768e", bg = "#3a3044" })
  hl("diffNewFile", { fg = "#73daca" })
  hl("diffOldFile", { fg = "#f7768e" })
  hl("diffFile", { fg = "#e0af68" })
  hl("diffFileId", { fg = "#bb9af7" })
  hl("gitconfigVariable", { fg = "#7dcfff" })
end

local function apply_custom_colors()
  if vim.g.colors_name == "tokyonight-storm" then
    apply_tokyonight_storm()
  end

  link("FloatBorder", "Normal")
  link("BlinkCmpMenuBorder", "FloatBorder")
  link("BlinkCmpDocBorder", "FloatBorder")
  link("BlinkCmpSignatureHelpBorder", "FloatBorder")

  -- barbar bufferline highlight links.
  link("BufferCurrentMod", "BufferCurrent")
  link("BufferCurrentIcon", vim.bo.modified and "BufferCurrentMod" or "BufferCurrent")
end

local function update_buffer_current_icon()
  -- Keep barbar's current-buffer icon highlight in sync with modified state.
  link("BufferCurrentIcon", vim.bo.modified and "BufferCurrentMod" or "BufferCurrent")
end

api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = api.nvim_create_augroup("dotfiles_colorscheme", { clear = true }),
  callback = apply_custom_colors,
})

api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost", "FileWritePost", "BufEnter", "ColorScheme" }, {
  group = api.nvim_create_augroup("dotfiles_bufferline_modified_icon", { clear = true }),
  callback = update_buffer_current_icon,
})

pcall(function()
  require("tokyonight").setup({
    style = "storm",
  })
end)

vim.cmd.colorscheme("tokyonight-storm")
apply_custom_colors()
