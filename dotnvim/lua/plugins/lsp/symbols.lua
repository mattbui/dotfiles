local METHOD = "textDocument/documentSymbol"
local PATH_SEPARATOR = "."
local symbols = {}

local cache = {}
local configured = false
local scope_kinds = {
  [vim.lsp.protocol.SymbolKind.Class] = true,
  [vim.lsp.protocol.SymbolKind.Constructor] = true,
  [vim.lsp.protocol.SymbolKind.Enum] = true,
  [vim.lsp.protocol.SymbolKind.Function] = true,
  [vim.lsp.protocol.SymbolKind.Interface] = true,
  [vim.lsp.protocol.SymbolKind.Method] = true,
  [vim.lsp.protocol.SymbolKind.Module] = true,
  [vim.lsp.protocol.SymbolKind.Struct] = true,
}
local kind_icons = {
  [vim.lsp.protocol.SymbolKind.Class] = "󱡠 ",
  [vim.lsp.protocol.SymbolKind.Constructor] = "󰒓 ",
  [vim.lsp.protocol.SymbolKind.Enum] = "󰦨 ",
  [vim.lsp.protocol.SymbolKind.Function] = "󰊕 ",
  [vim.lsp.protocol.SymbolKind.Interface] = "󱡠 ",
  [vim.lsp.protocol.SymbolKind.Method] = "󰊕 ",
  [vim.lsp.protocol.SymbolKind.Module] = "󰅩 ",
  [vim.lsp.protocol.SymbolKind.Struct] = "󱡠 ",
}

local function supports_document_symbol(client, bufnr)
  if type(client.supports_method) ~= "function" then
    return false
  end

  local ok, supported = pcall(client.supports_method, client, METHOD, bufnr)
  return ok and supported
end

local function get_clients(bufnr)
  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if supports_document_symbol(client, bufnr) then
      table.insert(clients, client)
    end
  end

  return clients
end

local function range_lines(range)
  if type(range) ~= "table" or type(range.start) ~= "table" or type(range["end"]) ~= "table" then
    return nil, nil
  end

  return range.start.line + 1, range["end"].line + 1
end

local function add_document_symbol(output, symbol, parents)
  local start_line, end_line = range_lines(symbol.range)
  if start_line == nil then
    return
  end

  local path_parts = vim.deepcopy(parents.path)
  local kind_parts = vim.deepcopy(parents.kind)
  table.insert(path_parts, symbol.name)
  table.insert(kind_parts, symbol.kind)

  local scope_index = parents.scope_index
  local scope_kind = parents.scope_kind
  local scope_start_line = parents.scope_start_line
  local scope_end_line = parents.scope_end_line
  if scope_kinds[symbol.kind] then
    scope_index = #path_parts
    scope_kind = symbol.kind
    scope_start_line = start_line
    scope_end_line = end_line
  end

  table.insert(output, {
    name = symbol.name,
    path = table.concat(path_parts, PATH_SEPARATOR),
    path_parts = path_parts,
    kind = symbol.kind,
    kind_parts = kind_parts,
    scope_index = scope_index,
    scope_kind = scope_kind,
    scope_start_line = scope_start_line,
    scope_end_line = scope_end_line,
    start_line = start_line,
    end_line = end_line,
  })

  if type(symbol.children) ~= "table" then
    return
  end

  for _, child in ipairs(symbol.children) do
    add_document_symbol(output, child, {
      path = path_parts,
      kind = kind_parts,
      scope_index = scope_index,
      scope_kind = scope_kind,
      scope_start_line = scope_start_line,
      scope_end_line = scope_end_line,
    })
  end
end

local function add_symbol_information(output, symbol)
  local location = symbol.location
  local start_line, end_line = range_lines(type(location) == "table" and location.range or nil)
  if start_line == nil then
    return
  end

  local path = symbol.name
  if type(symbol.containerName) == "string" and symbol.containerName ~= "" then
    path = symbol.containerName .. PATH_SEPARATOR .. symbol.name
  end

  local path_parts = vim.split(path, PATH_SEPARATOR, { plain = true })

  table.insert(output, {
    name = symbol.name,
    path = path,
    path_parts = path_parts,
    kind = symbol.kind,
    scope_index = scope_kinds[symbol.kind] and #path_parts or nil,
    scope_kind = scope_kinds[symbol.kind] and symbol.kind or nil,
    scope_start_line = scope_kinds[symbol.kind] and start_line or nil,
    scope_end_line = scope_kinds[symbol.kind] and end_line or nil,
    start_line = start_line,
    end_line = end_line,
  })
end

local function normalize_response(result)
  local output = {}
  if type(result) ~= "table" then
    return output
  end

  for _, symbol in ipairs(result) do
    if type(symbol.location) == "table" then
      add_symbol_information(output, symbol)
    else
      add_document_symbol(output, symbol, { path = {}, kind = {} })
    end
  end

  return output
end

local function scope_path(symbol)
  local path_parts = symbol.path_parts
  local kind_parts = symbol.kind_parts
  if type(path_parts) == "table" and symbol.scope_index ~= nil then
    return table.concat(vim.list_slice(path_parts, 1, symbol.scope_index), PATH_SEPARATOR)
  end

  if type(path_parts) ~= "table" or type(kind_parts) ~= "table" then
    return nil
  end

  for index = #kind_parts, 1, -1 do
    if scope_kinds[kind_parts[index]] then
      return table.concat(vim.list_slice(path_parts, 1, index), PATH_SEPARATOR)
    end
  end

  return nil
end

local function normalize_results(results)
  local normalized_symbols = {}

  for _, response in pairs(results or {}) do
    if response.err == nil then
      vim.list_extend(normalized_symbols, normalize_response(response.result))
    end
  end

  table.sort(normalized_symbols, function(left, right)
    if left.start_line ~= right.start_line then
      return left.start_line < right.start_line
    end

    return left.end_line > right.end_line
  end)

  return normalized_symbols
end

local function state(bufnr)
  cache[bufnr] = cache[bufnr] or {}
  return cache[bufnr]
end

local function changedtick(bufnr)
  return vim.api.nvim_buf_get_changedtick(bufnr)
end

local function set_symbols(bufnr, symbol_list)
  cache[bufnr] = {
    symbols = symbol_list,
    changedtick = changedtick(bufnr),
    pending = false,
    last_request = vim.uv.now(),
  }
end

local function request_params(bufnr)
  return {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }
end

local function request_async(bufnr)
  if #get_clients(bufnr) == 0 then
    return
  end

  local current = state(bufnr)
  if current.pending then
    return
  end

  local now = vim.uv.now()
  if current.last_request ~= nil and now - current.last_request < 1000 then
    return
  end

  current.pending = true
  current.last_request = now

  vim.lsp.buf_request_all(bufnr, METHOD, request_params(bufnr), function(results)
    if vim.api.nvim_buf_is_valid(bufnr) then
      set_symbols(bufnr, normalize_results(results))
    end
  end)
end

local function request_sync(bufnr, timeout_ms)
  if #get_clients(bufnr) == 0 then
    return nil, "No LSP document-symbol provider for current buffer"
  end

  local results = vim.lsp.buf_request_sync(bufnr, METHOD, request_params(bufnr), timeout_ms or 800)
  local symbol_list = normalize_results(results)
  set_symbols(bufnr, symbol_list)

  if vim.tbl_isempty(symbol_list) then
    return nil, "No LSP symbol for current cursor position"
  end

  return symbol_list
end

local function current_from_symbols(symbol_list, line)
  local current = nil

  for _, symbol in ipairs(symbol_list or {}) do
    if symbol.start_line <= line and line <= symbol.end_line then
      if current == nil then
        current = symbol
      else
        local symbol_span = symbol.end_line - symbol.start_line
        local current_span = current.end_line - current.start_line
        if symbol.start_line > current.start_line or symbol_span < current_span then
          current = symbol
        end
      end
    end
  end

  return current
end

function symbols.current(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  if opts.sync then
    local _, err = request_sync(bufnr, opts.timeout_ms)
    if err ~= nil then
      return nil, err
    end
  else
    local current = state(bufnr)
    if current.symbols == nil or current.changedtick ~= changedtick(bufnr) then
      request_async(bufnr)
    end
  end

  local symbol = current_from_symbols(state(bufnr).symbols, vim.api.nvim_win_get_cursor(0)[1])
  if symbol == nil then
    return nil, "No LSP symbol for current cursor position"
  end

  return symbol
end

function symbols.current_name(opts)
  opts = opts or {}

  local symbol = opts.symbol
  if symbol == nil then
    symbol = symbols.current(opts)
  end

  if symbol == nil then
    return ""
  end

  local name = scope_path(symbol)
  if name == nil then
    return ""
  end

  return name, {
    name = name,
    start_line = symbol.scope_start_line or symbol.start_line,
    end_line = symbol.scope_end_line or symbol.end_line,
  }
end

function symbols.current_display(opts)
  opts = opts or {}

  local symbol = opts.symbol
  if symbol == nil then
    symbol = symbols.current(opts)
  end

  if symbol == nil then
    return ""
  end

  local name = symbols.current_name({ symbol = symbol })
  local icon = kind_icons[symbol.scope_kind or symbol.kind] or ""
  return icon .. name
end

function symbols.setup()
  if configured then
    return
  end
  configured = true

  local group = vim.api.nvim_create_augroup("dotfiles_lsp_symbols", { clear = true })

  vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost" }, {
    group = group,
    callback = function(event)
      request_async(event.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(event)
      cache[event.buf] = nil
    end,
  })
end

return symbols
