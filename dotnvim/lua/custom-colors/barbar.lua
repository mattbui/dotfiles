local M = {}

local function link(group, target)
  vim.api.nvim_set_hl(0, group, { link = target })
end

function M.setup()
  link("BufferCurrentIndex", "BufferCurrentPin")
  link("BufferCurrentPinBtn", "BufferCurrentPin")
  link("BufferCurrentMod", "BufferCurrentPin")
  link("BufferCurrentModBtn", "BufferCurrentPin")

  link("BufferVisibleIndex", "BufferVisiblePin")
  link("BufferVisiblePinBtn", "BufferVisiblePin")
  link("BufferVisibleMod", "BufferVisiblePin")
  link("BufferVisibleModBtn", "BufferVisiblePin")

  link("BufferInactiveIndex", "BufferInactivePin")
  link("BufferInactivePinBtn", "BufferInactivePin")
  link("BufferInactiveMod", "BufferInactivePin")
  link("BufferInactiveModBtn", "BufferInactivePin")

  link("BufferAlternateIndex", "BufferAlternatePin")
  link("BufferAlternatePinBtn", "BufferAlternatePin")
  link("BufferAlternateMod", "BufferAlternatePin")
  link("BufferAlternateModBtn", "BufferAlternatePin")
end

return M
