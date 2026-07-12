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
    preview_scroll_up = "<PageUp>",
    preview_scroll_down = "<PageDown>",
    send_to_quickfix = "<S-CR>",
    toggle_select = false, -- this is already handled by <S-Up> and <S-Down>
    cycle_grep_modes = { "<S-Right>", "<S-Left>" },
    move_down = { "<Down>", "<Tab>" },
    move_up = { "<Up>", "<S-Tab>" },
    grep_jump_to_next_file = { "<C-n>", "<A-Down>" },
    grep_jump_to_prev_file = { "<C-p>", "<A-Up>" },
    cycle_previous_query = "<C-Up>",
  },
})

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

vim.keymap.set("n", "<C-p>", fff.find_files, { silent = true, desc = "Find files" })
vim.keymap.set("n", "<Leader>ff", fff.find_files, { silent = true, desc = "Find files" })
vim.keymap.set({ "n", "x" }, "<Leader>fg", fff.live_grep, { silent = true, desc = "Live grep" })
vim.keymap.set({ "n", "x" }, "<Leader>fw", fff.live_grep_under_cursor, { silent = true, desc = "Live grep selection" })
vim.keymap.set({ "n", "x" }, "<C-f>", fff.live_grep, { silent = true, desc = "Live grep" })
vim.keymap.set({ "n", "x" }, "<C-g>", fff.live_grep_under_cursor, { silent = true, desc = "Live grep selection" })
