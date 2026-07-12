require("mini.icons").setup()

local pick = require("mini.pick")

local function picker_window_config()
  local has_tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
  local has_statusline = vim.o.laststatus > 0
  local max_height = vim.o.lines - vim.o.cmdheight - (has_tabline and 1 or 0) - (has_statusline and 1 or 0)
  local max_width = vim.o.columns
  local height = math.floor(0.618 * max_height)
  local width = math.floor(0.618 * max_width)

  return {
    anchor = "NW",
    border = "single",
    col = math.floor(0.5 * (max_width - width)),
    height = height,
    row = math.floor(0.5 * (max_height - height)) + (has_tabline and 1 or 0),
    width = width,
  }
end

local function toggle_mark_and_move(direction)
  return function()
    local matches = pick.get_picker_matches()
    if matches == nil or matches.current_ind == nil or vim.tbl_isempty(matches.all_inds or {}) then
      return
    end

    local marked = {}
    local current_is_marked = false
    for _, ind in ipairs(matches.marked_inds or {}) do
      if ind == matches.current_ind then
        current_is_marked = true
      else
        table.insert(marked, ind)
      end
    end

    if not current_is_marked then
      table.insert(marked, matches.current_ind)
    end

    pick.set_picker_match_inds(marked, "marked")

    local current_pos = 1
    for pos, ind in ipairs(matches.all_inds) do
      if ind == matches.current_ind then
        current_pos = pos
        break
      end
    end

    local next_pos = (current_pos + direction - 1) % #matches.all_inds + 1
    pick.set_picker_match_inds({ matches.all_inds[next_pos] }, "current")
  end
end

local function tmux_navigate(char, direction)
  return {
    char = char,
    func = function()
      vim.schedule(function()
        vim.cmd("TmuxNavigate" .. direction)
      end)
      return true
    end,
  }
end

local function escape_or_close_preview()
  local state = pick.get_picker_state()
  if state == nil or state.windows == nil or state.buffers == nil then
    return true
  end

  local current_buf = vim.api.nvim_win_get_buf(state.windows.main)
  if current_buf == state.buffers.preview then
    vim.api.nvim_feedkeys(vim.keycode("<C-y>"), "m", false)
    return false
  end

  return true
end

pick.setup({
  mappings = {
    move_down = "<Tab>",
    move_up = "<S-Tab>",
    scroll_down = "<PageDown>",
    scroll_left = "<S-Left>",
    scroll_right = "<S-Right>",
    scroll_up = "<PageUp>",
    stop = "<C-q>",
    toggle_info = "",
    toggle_preview = "<C-y>",
    mark_all = "<S-CR>",

    escape_or_close_preview = {
      char = "<Esc>",
      func = escape_or_close_preview,
    },

    mark_and_move_down = {
      char = "<S-Down>",
      func = toggle_mark_and_move(1),
    },
    mark_and_move_up = {
      char = "<S-Up>",
      func = toggle_mark_and_move(-1),
    },

    navigate_left = tmux_navigate("<C-h>", "Left"),
    navigate_down = tmux_navigate("<C-j>", "Down"),
    navigate_up = tmux_navigate("<C-k>", "Up"),
    navigate_right = tmux_navigate("<C-l>", "Right"),
  },
  window = {
    config = picker_window_config,
  },
})

require("mini.extra").setup()

local function show_with_icons(buf_id, items, query)
  pick.default_show(buf_id, items, query, { show_icons = true })
end

local function trim_trailing_slash(path)
  return path:gsub("/$", "")
end

local function normalize_picker_path(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path:gsub("/$", ""), ":p"))
end

local function recent_buffer_timestamps()
  local timestamps = {}
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if info.name ~= "" and info.lastused ~= nil and info.lastused > 0 then
      timestamps[normalize_picker_path(info.name)] = info.lastused
    end
  end
  return timestamps
end

local function path_components(path)
  local components = {}
  path = trim_trailing_slash(path)
  if path == "" or path == "." then
    return components
  end

  for component in path:gmatch("[^/]+") do
    table.insert(components, component)
  end

  return components
end

local function parent_path(path)
  if path:sub(-1) == "/" then
    return trim_trailing_slash(path)
  end

  local parent = vim.fn.fnamemodify(path, ":h")
  return parent == "." and "" or parent
end

local function current_buffer_dir_components(current_file)
  if current_file == nil or current_file == "" then
    return {}
  end

  local relative = vim.fn.fnamemodify(current_file, ":.")
  return path_components(parent_path(relative))
end

local function path_distance(path, current_components)
  local components = path_components(parent_path(path))
  local shared_count = 0

  for index, component in ipairs(current_components) do
    if components[index] ~= component then
      break
    end
    shared_count = shared_count + 1
  end

  return #current_components + #components - 2 * shared_count
end

local function make_file_and_directory_rank(item, recent, current_components, current_path)
  local is_dir = item:sub(-1) == "/"
  local normalized_path = normalize_picker_path(item)
  return {
    distance = path_distance(item, current_components),
    is_current = normalized_path == current_path,
    is_dir = is_dir,
    recent = recent[normalized_path] or 0,
  }
end

local function sort_file_and_directory_items(items, current_file)
  while items[#items] == "" do
    items[#items] = nil
  end

  local recent = recent_buffer_timestamps()
  local current_components = current_buffer_dir_components(current_file)
  local current_path = current_file ~= "" and normalize_picker_path(current_file) or nil
  local ranks = {}
  for _, item in ipairs(items) do
    ranks[item] = make_file_and_directory_rank(item, recent, current_components, current_path)
  end

  table.sort(items, function(left, right)
    local left_rank = ranks[left]
    local right_rank = ranks[right]

    if left_rank.is_current ~= right_rank.is_current then
      return not left_rank.is_current
    end

    if left_rank.recent ~= right_rank.recent then
      return left_rank.recent > right_rank.recent
    end

    if left_rank.distance ~= right_rank.distance then
      return left_rank.distance < right_rank.distance
    end

    if left_rank.is_dir ~= right_rank.is_dir then
      return left_rank.is_dir
    end

    return left < right
  end)

  return items
end

local function make_file_and_directory_item(path)
  return {
    path = path,
    text = trim_trailing_slash(path),
  }
end

local function pick_files_and_directories()
  local current_file = vim.api.nvim_buf_get_name(0)

  pick.builtin.cli({
    command = { "fd", "--hidden", "--type", "f", "--type", "d", "--color", "never" },
    postprocess = function(items)
      local sorted_items = sort_file_and_directory_items(items, current_file)
      return vim.tbl_map(make_file_and_directory_item, sorted_items)
    end,
  }, {
    source = {
      name = "Files and directories",
      show = show_with_icons,
    },
  })
end

-- vim.keymap.set("n", "<C-p>", pick_files_and_directories, { silent = true, desc = "Find files and directories" })
vim.keymap.set("n", "<Leader>pd", pick_files_and_directories, { silent = true, desc = "Find directories and files" })

vim.keymap.set("n", "<Leader>D", function()
  MiniExtra.pickers.diagnostic({ scope = "current" })
end, { silent = true, desc = "Pick document diagnostics" })

vim.keymap.set("n", "<Leader>lD", function()
  MiniExtra.pickers.diagnostic({ scope = "all" })
end, { silent = true, desc = "Pick all diagnostics" })

vim.keymap.set("n", "<Leader>ls", function()
  MiniExtra.pickers.lsp({ scope = "document_symbol" })
end, { silent = true, desc = "Pick document symbols" })

vim.keymap.set("n", "<Leader>lS", function()
  MiniExtra.pickers.lsp({ scope = "workspace_symbol_live" })
end, { silent = true, desc = "Pick workspace symbols" })
