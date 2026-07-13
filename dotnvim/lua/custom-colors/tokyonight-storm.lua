local M = {}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

function M.setup()
  -- system UI colors
  hl("CursorLineNr", { fg = "#bb9af7" })
  hl("FloatBorder", { fg = "#636a8d", bg = "#1f2335" })
  hl("FloatTitle", { fg = "#636a8d", bg = "#1f2335" })
  hl("SignColumn", { fg = "#3b4261", bg = "#24283b" })
  hl("WinSeparator", { fg = "#3b4261", bold = true })

  -- git diff colors (fugitive use these)
  hl("DiffAdd", { fg = "#73daca", bg = "#2c3a44" })
  hl("DiffChange", { fg = "#e0af68", bg = "#383545" })
  hl("DiffDelete", { fg = "#f7768e", bg = "#3a3044" })
  hl("DiffText", { fg = "#a9b1d6", bg = "#363b50" })

  hl("diffAdded", { fg = "#73daca", bg = "#2c3a44" })
  hl("diffChanged", { fg = "#e0af68", bg = "#383545" })
  hl("diffRemoved", { fg = "#f7768e", bg = "#3a3044" })
  hl("diffNewFile", { fg = "#73daca" })
  hl("diffOldFile", { fg = "#f7768e" })
  hl("diffFile", { fg = "#e0af68" })
  hl("diffFileId", { fg = "#bb9af7" })
  hl("gitconfigVariable", { fg = "#7dcfff" })

  -- gitsigns colors,
  -- general idea:
  -- * more muted version of the diff colors above
  -- * preserve hue, slightly reduce saturation, and lower brightness by 20–30%.
  hl("GitSignsAdd", { fg = "#5fb0a3", bg = "#24283b" })
  hl("GitSignsChange", { fg = "#9b7f4f", bg = "#24283b" })
  hl("GitSignsDelete", { fg = "#c26378", bg = "#24283b" })
  hl("GitSignsChangedelete", { fg = "#9b7f4f", bg = "#24283b" })
  hl("GitSignsTopdelete", { fg = "#c26378", bg = "#24283b" })
  hl("GitSignsUntracked", { fg = "#5fb0a3", bg = "#24283b" })

  -- barbar colors
  -- general idea:
  -- * current buffer use the same bg colors as editor
  -- * other buffers use highlighted bg, and muted text to make current buffer pop
  -- * use itatic to indicate preview (default) vs permanent buffers (pinned)
  hl("BufferAlternate", { fg = "#c0caf5", bg = "#3b4261", italic = true })
  hl("BufferAlternatePin", { fg = "#c0caf5", bg = "#3b4261" })

  hl("BufferCurrent", { fg = "#c0caf5", bg = "#24283b", italic = true })
  hl("BufferCurrentPin", { fg = "#c0caf5", bg = "#24283b" })
  hl("BufferCurrentSign", { fg = "#bb9af7", bg = "#24283b" })
  hl("BufferCurrentSignRight", { fg = "#bb9af7", bg = "#24283b" })
  hl("BufferCurrentTarget", { fg = "#bb9af7" })
  hl("BufferCurrentADDED", { fg = "#73daca", bg = "#24283b" })
  hl("BufferCurrentCHANGED", { fg = "#e0af68", bg = "#24283b" })
  hl("BufferCurrentDELETED", { fg = "#f7768e", bg = "#24283b" })
  hl("BufferScrollArrow", { fg = "#7dcfff", bg = "#292e42" })
  hl("BufferInactiveTarget", { fg = "#bb9af7", bg = "#3b4261" })
  hl("BufferVisibleTarget", { fg = "#bb9af7", bg = "#3b4261" })

  hl("BufferVisible", { fg = "#636a8d", bg = "#292e42", italic = true })
  hl("BufferVisiblePin", { fg = "#636a8d", bg = "#292e42" })
  hl("BufferVisibleADDED", { fg = "#73daca", bg = "#292e42" })
  hl("BufferVisibleCHANGED", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferVisibleDELETED", { fg = "#f7768e", bg = "#292e42" })
  hl("BufferVisibleINFO", { fg = "#0db9d7", bg = "#292e42" })
  hl("BufferVisibleWARN", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferVisibleERROR", { fg = "#db4b4b", bg = "#292e42" })
  hl("BufferVisibleSign", { fg = "#636a8d", bg = "#292e42" })

  hl("BufferInactive", { fg = "#636a8d", bg = "#292e42", italic = true })
  hl("BufferInactivePin", { fg = "#636a8d", bg = "#292e42" })
  hl("BufferInactiveADDED", { fg = "#73daca", bg = "#292e42" })
  hl("BufferInactiveCHANGED", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferInactiveDELETED", { fg = "#f7768e", bg = "#292e42" })
  hl("BufferInactiveINFO", { fg = "#0db9d7", bg = "#292e42" })
  hl("BufferInactiveWARN", { fg = "#e0af68", bg = "#292e42" })
  hl("BufferInactiveERROR", { fg = "#db4b4b", bg = "#292e42" })
  hl("BufferInactiveSign", { fg = "#292e42", bg = "#292e42" })
end

return M
