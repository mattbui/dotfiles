local api = vim.api

local numbertoggle = api.nvim_create_augroup("numbertoggle", { clear = true })

api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number and vim.fn.mode() ~= "i" then
      vim.wo.relativenumber = true
    end
  end,
})

api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = false
    end
  end,
})

local terminal_timeoutlen = api.nvim_create_augroup("terminal_timeoutlen", { clear = true })

api.nvim_create_autocmd("TermEnter", {
  group = terminal_timeoutlen,
  callback = function()
    vim.opt.timeoutlen = 200
  end,
})

api.nvim_create_autocmd("TermLeave", {
  group = terminal_timeoutlen,
  callback = function()
    vim.opt.timeoutlen = 600
  end,
})

api.nvim_create_autocmd("FileType", {
  group = api.nvim_create_augroup("config.formatoptions", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

api.nvim_create_autocmd("TextYankPost", {
  group = api.nvim_create_augroup("highlight_on_yank", { clear = true }),
  desc = "Highlight on yank",
  callback = function()
    vim.hl.on_yank()
  end,
})

local autoclose = api.nvim_create_augroup("config.buffers.autoclose", { clear = true })

local function close_lonely_buffer(filetypes)
  api.nvim_create_autocmd("BufEnter", {
    group = autoclose,
    callback = function()
      if vim.fn.winnr("$") ~= 1 then
        return
      end

      local bufnr = api.nvim_get_current_buf()
      local command = filetypes[vim.bo[bufnr].filetype]
      if not command then
        return
      end

      vim.schedule(function()
        if not api.nvim_buf_is_valid(bufnr)
          or api.nvim_get_current_buf() ~= bufnr
          or vim.fn.winnr("$") ~= 1
        then
          return
        end

        vim.cmd(command)
      end)
    end,
  })
end

close_lonely_buffer({
  floaterm = "bdelete!",
  fugitive = "bdelete",
  fugitiveblame = "bdelete",
  git = "bdelete",
  qf = "bdelete",
  help = "bdelete",
})
