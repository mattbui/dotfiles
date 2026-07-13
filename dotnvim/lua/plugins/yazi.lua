vim.g.loaded_netrwPlugin = 1

require("yazi").setup({
  open_for_directories = true,
  floating_window_scaling_factor = {
    width = 0.9,
    height = 0.6,
  },
  highlight_hovered_buffers_in_same_directory = false,
  hooks = {
    before_opening_window = function(window_options)
      window_options.title = " Yazi "
    end,
  },
  -- Preserve the mappings from ~/.config/yazi instead of intercepting
  -- keys such as Ctrl-Q, Ctrl-Y, and Tab inside the terminal buffer.
  keymaps = false,
})

vim.keymap.set({ "n", "v" }, "<C-o>", "<Cmd>Yazi<CR>", { silent = true, desc = "Open Yazi at the current file" })
