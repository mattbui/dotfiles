vim.o.cmdheight = 0

require('vim._core.ui2').enable({
  enable = true,
  msg = {
    targets = {
      echo = 'msg',      -- nvim_echo() messages
      bufwrite = 'msg',  -- :write message.
      lua_print = 'msg', -- print() from :lua code.
      shell_ret = 'msg', -- :!cmd return code.
      undo = 'msg',      -- :undo and :redo message.
      wmsg = 'msg',      -- Warnings like search hit BOTTOM.
      quickfix = 'msg',  -- Quickfix navigation message.
    },
    pager   = { height = 1 },
    msg     = { height = 0.15, timeout = 4000 },
    dialog  = { height = 0.5 },
    cmd     = { height = 0.5 },
  },
})

-- Add border to msg, skip for now to avoid noise
-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = 'msg',
--   callback = function()
--     vim.api.nvim_win_set_config(0, {
--       border = 'single',
--     })
--   end,
-- })
