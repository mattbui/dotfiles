vim.g.floaterm_opener = "edit"
vim.g.floaterm_width = 0.8

local map = vim.keymap.set

map("n", "<C-t>", "<Cmd>FloatermToggle<CR>", { silent = true, desc = "Toggle floating terminal" })
map("t", "<C-t>", "<C-\\><C-n><Cmd>FloatermToggle<CR>", { silent = true, desc = "Toggle floating terminal" })
map("t", "<C-n>", "<C-\\><C-n><Cmd>FloatermNew<CR>", { silent = true, desc = "New floating terminal" })
map("t", "<M-Tab>", "<C-\\><C-n><Cmd>FloatermNext<CR>", { silent = true, desc = "Next floating terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { silent = true, desc = "Enter terminal normal mode" })

local function hide_and_navigate(direction)
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    vim.fn["floaterm#window#hide"](bufnr)
  end
  vim.cmd("TmuxNavigate" .. direction)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config.floaterm", { clear = true }),
  pattern = "floaterm",
  callback = function(event)
    vim.wo.number = false
    vim.wo.relativenumber = false

    local function map_navigation(key, direction)
      map("n", key, function()
        hide_and_navigate(direction)
      end, { buffer = event.buf, silent = true })
      map("t", key, function()
        vim.cmd.stopinsert()
        hide_and_navigate(direction)
      end, { buffer = event.buf, silent = true })
    end

    for key, direction in pairs({
      ["<C-h>"] = "Left",
      ["<C-j>"] = "Down",
      ["<C-k>"] = "Up",
      ["<C-l>"] = "Right",
    }) do
      map_navigation(key, direction)
    end
  end,
})
