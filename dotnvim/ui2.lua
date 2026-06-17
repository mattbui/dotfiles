local o = vim.o

o.cmdheight = 0

require('vim._core.ui2').enable({
  enable = true,
  msg = {
    targets = {
      empty = 'cmd',
      bufwrite = 'msg',
      confirm = 'cmd',
      emsg = 'msg',
      echo = 'cmd',
      echomsg = 'msg',
      echoerr = 'cmd',
      completion = 'cmd',
      list_cmd = 'cmd',
      lua_error = 'cmd',
      lua_print = 'msg',
      progress = 'cmd',
      rpc_error = 'cmd',
      quickfix = 'msg',
      search_cmd = 'cmd',
      search_count = 'cmd',
      shell_cmd = 'cmd',
      shell_err = 'cmd',
      shell_out = 'cmd',
      shell_ret = 'msg',
      undo = 'msg',
      verbose = 'cmd',
      wildlist = 'cmd',
      wmsg = 'msg',
      typed_cmd = 'cmd',
    },
    cmd = {
      height = 0.5,
    },
    dialog = {
      height = 0.5,
    },
    msg = {
      height = 0.3,
      timeout = 2000,
    },
    pager = {
      height = 0.5,
    },
  },
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'msg',
  callback = function()
    vim.api.nvim_win_set_config(0, {
      border = 'single',
    })
  end,
})
