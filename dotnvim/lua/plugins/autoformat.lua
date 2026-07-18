local conform = require("conform")

local M = {}

M.format_on_save = false

function M.is_enabled(bufnr)
  bufnr = bufnr or 0
  local buffer_setting = vim.b[bufnr].format_on_save
  if buffer_setting ~= nil then
    return buffer_setting
  end
  return M.format_on_save
end

local function prefer_project_venv(name)
  return function(_, ctx)
    local root = vim.fs.root(ctx.filename, { ".venv", "pyproject.toml", ".git" }) or vim.fn.getcwd()
    local local_tool = vim.fs.joinpath(root, ".venv", "bin", name)
    if vim.fn.executable(local_tool) == 1 then
      return local_tool
    end
    return name
  end
end

conform.setup({
  formatters_by_ft = {
    python = { "isort", "black" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
  },
  formatters = {
    isort = {
      command = prefer_project_venv("isort"),
    },
    black = {
      command = prefer_project_venv("black"),
    },
  },
  format_on_save = function(bufnr)
    if not M.is_enabled(bufnr) then
      return nil
    end
    return {
      timeout_ms = 3000,
      lsp_format = "fallback",
    }
  end,
})

local function format()
  conform.format({
    async = true,
    lsp_format = "fallback",
  })
end

vim.api.nvim_create_user_command("Format", format, { desc = "Format current buffer" })

local function set_format_on_save(enabled)
  vim.b.format_on_save = enabled
  vim.notify("Autoformat on save " .. (enabled and "enabled" or "disabled"))
end

vim.api.nvim_create_user_command("AutoFormatEnable", function()
  set_format_on_save(true)
end, { desc = "Enable autoformat on save for current buffer" })

vim.api.nvim_create_user_command("AutoFormatDisable", function()
  set_format_on_save(false)
end, { desc = "Disable autoformat on save for current buffer" })

vim.keymap.set({ "n", "x" }, "<Leader>lf", format, { silent = true, desc = "Format" })

return M
