local map = vim.keymap.set
local silent = { silent = true }
local commands = require("plugins.lsp.commands")
local floats = require("plugins.lsp.floats")

vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("config.lsp.float_close_keys", { clear = true }),
  callback = function(event)
    local win = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "" then
      return
    end

    for _, key in ipairs({ "<Esc>", "q" }) do
      vim.keymap.set("n", key, function()
        floats.close_current_or_fallback(key)
      end, {
        buffer = event.buf,
        silent = true,
        nowait = true,
        desc = "Close float",
      })
    end
  end,
})

vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("config.lsp.diagnostic_hover", { clear = true }),
  callback = floats.open_diagnostic_on_hold,
})

vim.api.nvim_create_autocmd("CursorMoved", {
  group = vim.api.nvim_create_augroup("config.lsp.diagnostic_hover_suppression", { clear = true }),
  callback = floats.reset_diagnostic_hover_suppression,
})

pcall(vim.keymap.del, "n", "<C-W>d")
pcall(vim.keymap.del, "n", "<C-W><C-D>")
map("n", "<Esc>", floats.escape, vim.tbl_extend("force", silent, { desc = "Clear search or hide diagnostic" }))

map("n", "<Leader>j", floats.jump_to_float, vim.tbl_extend("force", silent, { desc = "Jump to float" }))
map("n", "<Leader>k", floats.jump_or_hover, vim.tbl_extend("force", silent, { desc = "Jump to float or hover" }))
map("n", "<Leader>d", floats.open_diagnostic, vim.tbl_extend("force", silent, { desc = "Show diagnostic" }))
map("n", "gk", floats.show_documentation, vim.tbl_extend("force", silent, { desc = "Hover" }))

map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", silent, { desc = "Definition" }))
map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", silent, { desc = "References" }))
map("n", "gn", function()
  vim.diagnostic.jump({ count = 1 })
end, vim.tbl_extend("force", silent, { desc = "Next diagnostic" }))

map("n", "gp", function()
  vim.diagnostic.jump({ count = -1 })
end, vim.tbl_extend("force", silent, { desc = "Previous diagnostic" }))

map("n", "<Leader>lr", vim.lsp.buf.rename, vim.tbl_extend("force", silent, { desc = "Rename" }))
map({ "n", "x" }, "<Leader>la", vim.lsp.buf.code_action, vim.tbl_extend("force", silent, { desc = "Code action" }))

map("n", "<Leader>lt", vim.lsp.buf.type_definition, vim.tbl_extend("force", silent, { desc = "Type definition" }))
map("n", "<Leader>li", vim.lsp.buf.implementation, vim.tbl_extend("force", silent, { desc = "Implementation" }))
map("n", "<Leader>lo", commands.organize_imports, vim.tbl_extend("force", silent, { desc = "Organize imports" }))
map("n", "<Leader>lv", commands.toggle_virtual_text, vim.tbl_extend("force", silent, { desc = "Toggle virtual text" }))
map("n", "<Leader>lh", commands.toggle_inlay_hints, vim.tbl_extend("force", silent, { desc = "Toggle inlay hints" }))

local highlight_group = vim.api.nvim_create_augroup("config.lsp.document_highlight", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = highlight_group,
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    if commands.inlay_hints_enabled and client:supports_method("textDocument/inlayHint", event.buf) then
      vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
    end

    if client:supports_method("textDocument/documentHighlight", event.buf) then
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = highlight_group,
        buffer = event.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = highlight_group,
        buffer = event.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})
