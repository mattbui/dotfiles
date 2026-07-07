local conform = require("conform")

local autoformat = {}

autoformat.format_on_save = true

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
  format_on_save = autoformat.format_on_save and {
    timeout_ms = 3000,
    lsp_format = "fallback",
  } or nil,
})

local function format()
  conform.format({
    async = true,
    lsp_format = "fallback",
  })
end

vim.api.nvim_create_user_command("Format", format, { desc = "Format current buffer" })

vim.keymap.set({ "n", "x" }, "<Leader>cf", format, { silent = true, desc = "Format" })

return autoformat
