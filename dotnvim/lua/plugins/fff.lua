pcall(vim.cmd.packadd, "fff.nvim")

local ok, fff = pcall(require, "fff")
if not ok then
  vim.schedule(function()
    vim.notify("fff.nvim is not available; run vim.pack update/repair", vim.log.levels.WARN)
  end)
  return
end

local function toggle_and_move(direction)
  local ok_picker, picker = pcall(require, "fff.picker_ui.picker_ui")
  local ok_state, state = pcall(require, "fff.picker_ui.picker_ui_state")
  if not ok_picker or not ok_state or not picker.state.active then
    return
  end

  state.toggle_selection()
  picker.render_list()
  picker[direction]()
end

local function map_toggle_move(buf, filetype)
  local modes = filetype == "fff_input" and { "n", "i" } or "n"

  vim.keymap.set(modes, "<S-Down>", function()
    toggle_and_move("move_down")
  end, { buffer = buf, silent = true, desc = "Toggle selection and move down" })

  vim.keymap.set(modes, "<S-Up>", function()
    toggle_and_move("move_up")
  end, { buffer = buf, silent = true, desc = "Toggle selection and move up" })
end

local function map_tmux_navigation(buf, filetype)
  local modes = filetype == "fff_input" and { "n", "i" } or "n"

  local function close_and_navigate(direction)
    local ok_picker, picker = pcall(require, "fff.picker_ui.picker_ui")
    if ok_picker and picker.state.active then
      picker.close()
    end

    vim.schedule(function()
      vim.cmd("TmuxNavigate" .. direction)
    end)
  end

  local mappings = {
    ["<C-h>"] = "Left",
    ["<C-j>"] = "Down",
    ["<C-k>"] = "Up",
    ["<C-l>"] = "Right",
  }

  for key, direction in pairs(mappings) do
    vim.keymap.set(modes, key, function()
      close_and_navigate(direction)
    end, {
      buffer = buf,
      silent = true,
      desc = "Navigate " .. direction:lower(),
    })
  end
end

-- fff creates its picker buffers dynamically; add local compatibility mappings
-- after its FileType setup so they win over picker defaults.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles.fff.compat", { clear = true }),
  pattern = { "fff_input", "fff_list", "fff_preview" },
  callback = function(ev)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        map_toggle_move(ev.buf, ev.match)
        map_tmux_navigation(ev.buf, ev.match)
      end
    end)
  end,
})

fff.setup({
  layout = {
    width = 0.8,
    height = 0.6,
    prompt_position = "top",
    preview_position = "right",
    preview_size = 0.5,
    border = "single",
  },
  preview = {
    enabled = true,
    line_numbers = true,
  },
  keymaps = {
    close = { "<Esc>", "<C-q>" },
    preview_scroll_up = "<C-b>",
    preview_scroll_down = "<C-f>",
    send_to_quickfix = "<S-CR>",
  },
})

vim.api.nvim_create_user_command("Files", function(opts)
  if opts.args ~= "" then
    fff.find_files_in_dir(opts.args)
    return
  end

  fff.find_files()
end, {
  bang = true,
  nargs = "?",
  complete = "dir",
  desc = "Find files",
})

vim.api.nvim_create_user_command("Rg", function(opts)
  if opts.args ~= "" then
    fff.live_grep({ query = opts.args })
    return
  end

  fff.live_grep()
end, {
  bang = true,
  nargs = "*",
  desc = "Live grep",
})

vim.keymap.set("n", "<C-p>", "<Cmd>Files<CR>", { silent = true, desc = "Find files" })
vim.keymap.set("n", "<C-g>", "<Cmd>Rg<CR>", { silent = true, desc = "Live grep" })
