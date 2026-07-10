local M = {}

local function truncate_diagnostic(diagnostic)
  local max_width = 50
  local message = diagnostic.message:gsub("%s+", " ")
  if vim.fn.strdisplaywidth(message) <= max_width then
    return message
  end
  return vim.fn.strcharpart(message, 0, max_width - 1) .. "…"
end

M.virtual_text = {
  format = truncate_diagnostic,
}

M.virtual_text_enabled = false
M.inlay_hints_enabled = true

function M.enable_virtual_text()
  M.virtual_text_enabled = true
  vim.diagnostic.config({ virtual_text = M.virtual_text })
end

function M.disable_virtual_text()
  M.virtual_text_enabled = false
  vim.diagnostic.config({ virtual_text = false })
end

function M.toggle_virtual_text()
  M.virtual_text_enabled = not M.virtual_text_enabled
  vim.diagnostic.config({ virtual_text = M.virtual_text_enabled and M.virtual_text or false })
end

function M.enable_inlay_hints()
  M.inlay_hints_enabled = true
  vim.lsp.inlay_hint.enable(true)
end

function M.disable_inlay_hints()
  M.inlay_hints_enabled = false
  vim.lsp.inlay_hint.enable(false)
end

function M.toggle_inlay_hints()
  M.inlay_hints_enabled = not M.inlay_hints_enabled
  vim.lsp.inlay_hint.enable(M.inlay_hints_enabled)
end

function M.organize_imports()
  if vim.bo.filetype == "python" then
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      vim.notify("Cannot organize imports for unnamed buffer", vim.log.levels.WARN)
      return
    end

    local root = vim.fs.root(file, { ".venv", "pyproject.toml", ".git" }) or vim.fn.getcwd()
    local isort = vim.fs.joinpath(root, ".venv", "bin", "isort")
    if vim.fn.executable(isort) ~= 1 then
      isort = "isort"
    end
    if vim.fn.executable(isort) ~= 1 then
      vim.notify("isort is not executable", vim.log.levels.ERROR)
      return
    end
    if vim.bo.modified then
      vim.cmd.write()
    end

    vim.system({ isort, file }, { text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          local stderr = result.stderr or ""
          local stdout = result.stdout or ""
          local message = stderr ~= "" and stderr or stdout
          vim.notify(vim.trim(message), vim.log.levels.ERROR)
          return
        end
        vim.cmd.checktime()
      end)
    end)
    return
  end

  vim.lsp.buf.code_action({
    context = {
      only = { "source.organizeImports" },
    },
    apply = true,
  })
end

vim.api.nvim_create_user_command("LspVirtualTextEnable", M.enable_virtual_text, {
  desc = "Enable LSP diagnostic virtual text",
})
vim.api.nvim_create_user_command("LspVirtualTextDisable", M.disable_virtual_text, {
  desc = "Disable LSP diagnostic virtual text",
})
vim.api.nvim_create_user_command("LspVirtualTextToggle", M.toggle_virtual_text, {
  desc = "Toggle LSP diagnostic virtual text",
})

vim.api.nvim_create_user_command("LspInlayHintsEnable", M.enable_inlay_hints, {
  desc = "Enable LSP inlay hints",
})
vim.api.nvim_create_user_command("LspInlayHintsDisable", M.disable_inlay_hints, {
  desc = "Disable LSP inlay hints",
})
vim.api.nvim_create_user_command("LspInlayHintsToggle", M.toggle_inlay_hints, {
  desc = "Toggle LSP inlay hints",
})

vim.api.nvim_create_user_command("LspOrganizeImports", M.organize_imports, {
  desc = "Organize imports with LSP",
})

return M
