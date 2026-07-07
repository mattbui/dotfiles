local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local symbols = require("plugins.lsp.symbols")

local function current_path(kind)
  local modifier = kind == "absolute" and "%:p" or "%"
  local path = vim.fn.expand(modifier)

  if path == nil or path == "" then
    notify("No file path for current buffer", vim.log.levels.WARN)
    return nil
  end

  return path
end

local function copy(value)
  vim.fn.setreg('"', value)
  pcall(vim.fn.setreg, "+", value)
  notify("Yanked " .. value)
end

local function path_label(path, suffix)
  local label = vim.fn.fnamemodify(path, ":t")
  if suffix ~= nil and suffix ~= "" then
    label = label .. suffix
  end

  return label
end

local function markdown_label(label)
  return string.gsub(label, "%]", "\\]")
end

local function markdown_link(label, target)
  return string.format("[%s](%s)", markdown_label(label), target)
end

local function yank_path(kind)
  local path = current_path(kind)
  if not path then
    return
  end

  if kind == "absolute" then
    copy(path)
    return
  end

  copy(markdown_link(path_label(path), path))
end

local function yank_path_line(kind)
  local path = current_path(kind)
  if not path then
    return
  end

  local line = vim.fn.line(".")
  copy(markdown_link(path_label(path, ":" .. line), string.format("%s:%d", path, line)))
end

local function yank_path_range(kind, opts)
  if opts.range == 0 then
    notify("Yank path range commands require a line range", vim.log.levels.WARN)
    return
  end

  local path = current_path(kind)
  if not path then
    return
  end

  local start_line = math.min(opts.line1, opts.line2)
  local end_line = math.max(opts.line1, opts.line2)

  if start_line == end_line then
    copy(markdown_link(path_label(path, ":" .. start_line), string.format("%s:%d", path, start_line)))
    return
  end

  copy(markdown_link(path_label(path, string.format(":%d-%d", start_line, end_line)), string.format("%s:%d-%d", path, start_line, end_line)))
end

local function yank_path_tag(kind)
  local path = current_path(kind)
  if not path then
    return
  end

  local symbol, err = symbols.current({ sync = true })
  if not symbol then
    notify(err, vim.log.levels.WARN)
    return
  end

  local symbol_name, named_symbol = symbols.current_name({ symbol = symbol })
  if symbol_name == "" then
    notify("No LSP class/method/function symbol for current cursor position", vim.log.levels.WARN)
    return
  end

  local start_line = named_symbol and named_symbol.start_line or symbol.start_line

  if start_line == nil then
    copy(markdown_link(symbol_name, string.format("%s::%s", path, symbol_name)))
    return
  end

  copy(markdown_link(symbol_name, string.format("%s:%d::%s", path, start_line, symbol_name)))
end

vim.api.nvim_create_user_command("YankRelativePath", function()
  yank_path("relative")
end, {})

vim.api.nvim_create_user_command("YankAbsolutePath", function()
  yank_path("absolute")
end, {})

vim.api.nvim_create_user_command("YankRelativePathLine", function()
  yank_path_line("relative")
end, {})

vim.api.nvim_create_user_command("YankAbsolutePathLine", function()
  yank_path_line("absolute")
end, {})

vim.api.nvim_create_user_command("YankRelativePathRange", function(opts)
  yank_path_range("relative", opts)
end, { range = true })

vim.api.nvim_create_user_command("YankAbsolutePathRange", function(opts)
  yank_path_range("absolute", opts)
end, { range = true })

vim.api.nvim_create_user_command("YankRelativePathTag", function()
  yank_path_tag("relative")
end, {})

vim.api.nvim_create_user_command("YankAbsolutePathTag", function()
  yank_path_tag("absolute")
end, {})
