local map = vim.keymap.set
local silent = { silent = true }
local commands = require("plugins.lsp.commands")

local function has_lsp_floating_preview(bufnr)
  local ok, win = pcall(vim.api.nvim_buf_get_var, bufnr, "lsp_floating_preview")
  return ok and vim.api.nvim_win_is_valid(win)
end

local function focus_current_float()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, win = pcall(vim.api.nvim_buf_get_var, bufnr, "lsp_floating_preview")
  if ok and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    return
  end

  for _, float_win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(float_win)
    if config.relative ~= "" and config.focusable ~= false then
      vim.api.nvim_set_current_win(float_win)
      return
    end
  end
end

local function show_documentation()
  local filetype = vim.bo.filetype
  if filetype == "vim" or filetype == "help" then
    vim.cmd("help " .. vim.fn.expand("<cword>"))
    return
  end
  vim.lsp.buf.hover({
    border = "single",
    focusable = false,
  })
end

local function close_float_or_fallback(key)
  local win = vim.api.nvim_get_current_win()
  local config = vim.api.nvim_win_get_config(win)

  if config.relative ~= "" then
    vim.cmd.close()
    return
  end

  if key == "<Esc>" then
    vim.cmd.nohlsearch()
    return
  end

  vim.api.nvim_feedkeys(key, "n", false)
end

vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("dotfiles_float_close_keys", { clear = true }),
  callback = function(event)
    local win = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "" then
      return
    end

    for _, key in ipairs({ "<Esc>", "q" }) do
      vim.keymap.set("n", key, function()
        close_float_or_fallback(key)
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
  group = vim.api.nvim_create_augroup("dotfiles_diagnostic_hover", { clear = true }),
  callback = function()
    if vim.api.nvim_get_mode().mode ~= "n" then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    if has_lsp_floating_preview(bufnr) then
      return
    end

    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diagnostics = vim.diagnostic.get(bufnr, { lnum = lnum })
    if not vim.tbl_isempty(diagnostics) then
      vim.diagnostic.open_float({
        focusable = false,
        scope = "cursor",
        close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre" },
      })
      return
    end
  end,
})

pcall(vim.keymap.del, "n", "<C-W>d")
pcall(vim.keymap.del, "n", "<C-W><C-D>")
map("n", "<Leader>f", focus_current_float, vim.tbl_extend("force", silent, { desc = "Focus floating window" }))

map("n", "gk", show_documentation, vim.tbl_extend("force", silent, { desc = "Hover" }))
map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", silent, { desc = "Definition" }))
map("n", "gy", vim.lsp.buf.type_definition, vim.tbl_extend("force", silent, { desc = "Type definition" }))
map("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", silent, { desc = "Implementation" }))
map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", silent, { desc = "References" }))
map("n", "gn", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, vim.tbl_extend("force", silent, { desc = "Next diagnostic" }))

map("n", "gp", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, vim.tbl_extend("force", silent, { desc = "Previous diagnostic" }))

map("n", "<Leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", silent, { desc = "Rename" }))
map({ "n", "x" }, "<Leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", silent, { desc = "Code action" }))

map("n", "<Leader>cs", commands.organize_imports, vim.tbl_extend("force", silent, { desc = "Organize imports" }))

local highlight_group = vim.api.nvim_create_augroup("dotfiles_lsp_document_highlight", { clear = true })

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
