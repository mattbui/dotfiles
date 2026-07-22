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

-- put quickfix selection to the the nearest entry to the current cursor when possible
api.nvim_create_autocmd("BufWinEnter", {
  group = api.nvim_create_augroup("quickfix_nearest_entry", { clear = true }),
  pattern = "quickfix",
  desc = "Select quickfix entry nearest to the cursor",
  callback = function()
    local wininfo = vim.fn.getwininfo(api.nvim_get_current_win())[1]
    if not wininfo or wininfo.quickfix ~= 1 or wininfo.loclist == 1 then
      return
    end

    local previous_win = vim.fn.win_getid(vim.fn.winnr("#"))
    if previous_win == 0 or not api.nvim_win_is_valid(previous_win) then
      return
    end

    local source_buf = api.nvim_win_get_buf(previous_win)
    local source_line = api.nvim_win_get_cursor(previous_win)[1]
    local items = vim.fn.getqflist({ items = 0 }).items
    local closest_idx
    local closest_distance = math.huge

    for idx, item in ipairs(items) do
      if item.bufnr == source_buf then
        local distance = math.abs(item.lnum - source_line)
        if distance < closest_distance then
          closest_idx = idx
          closest_distance = distance
        end
      end
    end

    if closest_idx then
      local qf_id = vim.fn.getqflist({ id = 0 }).id
      vim.schedule(function()
        if vim.fn.getqflist({ id = 0 }).id == qf_id then
          vim.fn.setqflist({}, "a", { id = qf_id, idx = closest_idx })
        end
      end)
    end
  end,
})
