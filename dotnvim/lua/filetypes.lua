local api = vim.api

local filetype_group = api.nvim_create_augroup("dotfiles_filetypes", { clear = true })

api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = filetype_group,
  pattern = { "lfrc", "direnvrc" },
  callback = function()
    vim.bo.filetype = "sh"
  end,
})

local indent_group = api.nvim_create_augroup("dotfiles_filetype_settings", { clear = true })

local function set_indent(filetypes, size, extra)
  api.nvim_create_autocmd("FileType", {
    group = indent_group,
    pattern = filetypes,
    callback = function()
      vim.bo.tabstop = size
      vim.bo.shiftwidth = size
      vim.bo.softtabstop = size

      if extra then
        extra()
      end
    end,
  })
end

set_indent({ "html", "yaml", "json", "lua", "markdown" }, 2)
set_indent("typescript", 2, function()
  vim.bo.expandtab = true
  vim.bo.softtabstop = 2
end)
set_indent("vim", 2, function()
  vim.wo.foldmethod = "marker"
end)
