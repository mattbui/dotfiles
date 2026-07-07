local M = {}

M.symbols = {
  error = " ",
  warn = " ",
  info = " ",
  hint = " ",
}

M.signs = {
  text = {
    [vim.diagnostic.severity.ERROR] = M.symbols.error,
    [vim.diagnostic.severity.WARN] = M.symbols.warn,
    [vim.diagnostic.severity.INFO] = M.symbols.info,
    [vim.diagnostic.severity.HINT] = M.symbols.hint,
  },
}

return M
