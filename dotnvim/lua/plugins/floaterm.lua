vim.g.floaterm_opener = "edit"
vim.g.floaterm_title = " Floaterm ($1/$2) "
vim.g.floaterm_width = 0.8

local map = vim.keymap.set
local floaterm_group = vim.api.nvim_create_augroup("config.floaterm", { clear = true })

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
  group = floaterm_group,
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

-- Floaterm does not forward its title to Neovim's native border when
-- 'winborder' is set, so apply it after each floating terminal opens.
vim.api.nvim_create_autocmd("User", {
  group = floaterm_group,
  pattern = "FloatermOpen",
  callback = function()
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
      local bufnr = vim.api.nvim_win_get_buf(winid)
      local window_options = vim.api.nvim_win_get_config(winid)

      if vim.bo[bufnr].filetype == "floaterm" and window_options.relative ~= "" then
        local title = vim.fn["floaterm#window#make_title"](
          bufnr,
          vim.b[bufnr].floaterm_title or vim.g.floaterm_title
        )

        vim.api.nvim_win_set_config(winid, {
          title = title,
          title_pos = vim.b[bufnr].floaterm_titleposition or vim.g.floaterm_titleposition,
        })
      end
    end
  end,
})
