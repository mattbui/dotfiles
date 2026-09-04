local colors = require("colors")

sbar.bar({
  position = "bottom",
  height = 28,
  margin = 0,
  y_offset = 0,
  display = "all",
  color = colors.transparent,
  border_width = 0,
  shadow = false,
  sticky = true,
  padding_left = 20,
  padding_right = 20,
  blur_radius = 0,
  topmost = "window",
})

sbar.default({
  position = "center",
  updates = "when_shown",
  drawing = true,
  icon = {
    color = colors.text,
    padding_left = 0,
    padding_right = 0,
    y_offset = 0,
  },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = 0,
  padding_right = 0,
})

require("controller").setup()
