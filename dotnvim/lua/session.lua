local session_file = "Session.vim"
local no_file_args = vim.fn.argc(-1) == 0

local group = vim.api.nvim_create_augroup("NativeAutoSession", { clear = true })

local function do_bufread_for_restored_buffers()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buffer)
      and vim.api.nvim_buf_get_name(buffer) ~= ""
      and vim.bo[buffer].filetype == ""
    then
      vim.api.nvim_buf_call(buffer, function()
        vim.cmd("doautocmd BufRead")
      end)
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    if not no_file_args or vim.fn.filereadable(session_file) == 0 then
      return
    end

    vim.cmd.source(vim.fn.fnameescape(session_file))
    do_bufread_for_restored_buffers()
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    if not no_file_args then
      return
    end

    vim.cmd("argglobal")
    vim.cmd("%argdelete")
    vim.cmd("mksession! " .. vim.fn.fnameescape(session_file))
  end,
})
