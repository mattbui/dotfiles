vim.o.cmdheight = 0

require('vim._core.ui2').enable({
  enable = true,
  msg = {
    targets = 'msg',
    pager   = { height = 1 },
    msg     = { height = 0.2, timeout = 4000 },
    dialog  = { height = 0.5 },
    cmd     = { height = 0.5 },
  },
})

-- Render UI2's native showcmd events and macro recording keys in one float.
require("float-keys").setup()

-- Add border to msg, skip for now to avoid noise
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'msg',
  callback = function()
    vim.api.nvim_win_set_config(0, {
      border = 'none',
    })
  end,
})
