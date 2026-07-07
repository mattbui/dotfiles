local diagnostics = {}

diagnostics.symbols = {
  error = " ",
  warn = " ",
  info = " ",
  hint = " ",
}

diagnostics.signs = {
  text = {
    [vim.diagnostic.severity.ERROR] = diagnostics.symbols.error,
    [vim.diagnostic.severity.WARN] = diagnostics.symbols.warn,
    [vim.diagnostic.severity.INFO] = diagnostics.symbols.info,
    [vim.diagnostic.severity.HINT] = diagnostics.symbols.hint,
  },
}

return diagnostics
