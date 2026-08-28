local M = {}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

function M.setup()
  local palette = require("rose-pine.palette")
  local blend = require("rose-pine.utilities").blend

  -- System UI: rose replaces the magenta accent used by the Tokyo theme.
  hl("CursorLineNr", { fg = palette.rose })
  hl("FloatBorder", { fg = palette.muted, bg = palette.surface })
  hl("FloatTitle", { fg = palette.foam, bg = palette.surface })
  hl("SignColumn", { fg = palette.muted, bg = palette.base })
  hl("WinSeparator", { fg = palette.overlay, bold = true })

  -- Git diff colors use semantic foregrounds over restrained tinted backgrounds.
  local diff_add = { fg = palette.foam, bg = blend(palette.foam, palette.base, 0.14) }
  local diff_change = { fg = palette.gold, bg = blend(palette.gold, palette.base, 0.14) }
  local diff_delete = { fg = palette.love, bg = blend(palette.love, palette.base, 0.14) }
  local diff_text = { fg = palette.text, bg = blend(palette.rose, palette.base, 0.24) }

  hl("DiffAdd", diff_add)
  hl("DiffChange", diff_change)
  hl("DiffDelete", diff_delete)
  hl("DiffText", diff_text)
  hl("diffAdded", diff_add)
  hl("diffChanged", diff_change)
  hl("diffRemoved", diff_delete)
  hl("diffNewFile", { fg = palette.foam })
  hl("diffOldFile", { fg = palette.love })
  hl("diffFile", { fg = palette.gold })
  hl("diffFileId", { fg = palette.rose })
  hl("gitconfigVariable", { fg = palette.foam })

  -- Keep signs quieter than the corresponding diff text.
  local sign_add = blend(palette.foam, palette.base, 0.65)
  local sign_change = blend(palette.gold, palette.base, 0.65)
  local sign_delete = blend(palette.love, palette.base, 0.65)
  hl("GitSignsAdd", { fg = sign_add, bg = palette.base })
  hl("GitSignsChange", { fg = sign_change, bg = palette.base })
  hl("GitSignsDelete", { fg = sign_delete, bg = palette.base })
  hl("GitSignsChangedelete", { fg = sign_change, bg = palette.base })
  hl("GitSignsTopdelete", { fg = sign_delete, bg = palette.base })
  hl("GitSignsUntracked", { fg = sign_add, bg = palette.base })

  -- Barbar mirrors the existing Tokyo structure and its magenta accent slots.
  hl("BufferAlternate", { fg = palette.text, bg = palette.overlay, italic = true })
  hl("BufferAlternatePin", { fg = palette.text, bg = palette.overlay })
  hl("BufferAlternateSignRight", { fg = palette.overlay, bg = palette.overlay })

  hl("BufferCurrent", { fg = palette.text, bg = palette.base, italic = true })
  hl("BufferCurrentPin", { fg = palette.text, bg = palette.base })
  hl("BufferCurrentSign", { fg = palette.rose, bg = palette.base })
  hl("BufferCurrentSignRight", { fg = palette.base, bg = palette.base })
  hl("BufferCurrentTarget", { fg = palette.rose })
  hl("BufferCurrentADDED", { fg = palette.foam, bg = palette.base })
  hl("BufferCurrentCHANGED", { fg = palette.gold, bg = palette.base })
  hl("BufferCurrentDELETED", { fg = palette.love, bg = palette.base })
  hl("BufferScrollArrow", { fg = palette.foam, bg = palette.highlight_low })
  hl("BufferInactiveTarget", { fg = palette.rose, bg = palette.overlay })
  hl("BufferVisibleTarget", { fg = palette.rose, bg = palette.overlay })

  for _, state in ipairs({ "Visible", "Inactive" }) do
    local prefix = "Buffer" .. state
    hl(prefix, { fg = palette.subtle, bg = palette.overlay, italic = true })
    hl(prefix .. "Pin", { fg = palette.subtle, bg = palette.overlay })
    hl(prefix .. "ADDED", { fg = palette.foam, bg = palette.overlay })
    hl(prefix .. "CHANGED", { fg = palette.gold, bg = palette.overlay })
    hl(prefix .. "DELETED", { fg = palette.love, bg = palette.overlay })
    hl(prefix .. "INFO", { fg = palette.foam, bg = palette.overlay })
    hl(prefix .. "WARN", { fg = palette.gold, bg = palette.overlay })
    hl(prefix .. "ERROR", { fg = palette.love, bg = palette.overlay })
    hl(prefix .. "Sign", { fg = palette.muted, bg = palette.overlay })
    hl(prefix .. "SignRight", { fg = palette.overlay, bg = palette.overlay })
  end
end

return M
