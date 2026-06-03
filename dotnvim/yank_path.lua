local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

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

local function current_tag()
  local ok, tag = pcall(vim.fn["tagbar#currenttag"], "%s", "", "f")
  if not ok then
    notify("Tagbar is not available", vim.log.levels.WARN)
    return nil
  end

  if tag == nil or tag == "" then
    notify("No Tagbar tag for current cursor position", vim.log.levels.WARN)
    return nil
  end

  return tag
end

local function format_tagbar_tag(tag)
  if type(tag) ~= "table" or tag.name == nil then
    return nil
  end

  local formatted = tag.name
  if tag.path ~= nil and tag.path ~= "" then
    local sro = "::"
    if type(tag.typeinfo) == "table" and tag.typeinfo.sro ~= nil then
      sro = tag.typeinfo.sro
    end

    formatted = tag.path .. sro .. tag.name
  end

  if type(tag.fields) == "table" and tag.fields.signature ~= nil then
    formatted = formatted .. "()"
  end

  return formatted
end

local function tag_start_line(tag_name)
  local ok, fileinfo = pcall(vim.fn["tagbar#state#get_current_file"], 1)
  if not ok or type(fileinfo) ~= "table" or type(fileinfo.fline) ~= "table" then
    return nil
  end

  local cursor_line = vim.fn.line(".")
  local nearest_line = nil

  for _, tag in pairs(fileinfo.fline) do
    local fields = type(tag) == "table" and tag.fields or nil
    local start_line = type(fields) == "table" and tonumber(fields.line) or nil
    local end_line = type(fields) == "table" and tonumber(fields["end"]) or nil
    local formatted = format_tagbar_tag(tag)

    if start_line ~= nil and formatted == tag_name and start_line <= cursor_line then
      if end_line ~= nil and end_line >= cursor_line then
        return start_line
      end

      if nearest_line == nil or start_line > nearest_line then
        nearest_line = start_line
      end
    end
  end

  return nearest_line
end

local function yank_path_tag(kind)
  local path = current_path(kind)
  if not path then
    return
  end

  local tag = current_tag()
  if not tag then
    return
  end

  local line = tag_start_line(tag)
  if line == nil then
    copy(markdown_link(tag, string.format("%s::%s", path, tag)))
    return
  end

  copy(markdown_link(tag, string.format("%s:%d::%s", path, line, tag)))
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
