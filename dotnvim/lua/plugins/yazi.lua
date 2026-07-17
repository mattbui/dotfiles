vim.g.loaded_netrwPlugin = 1

local function update_yazi_start_dir()
  vim.env.YAZI_START_DIR = vim.uv.cwd()
end

update_yazi_start_dir()
vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("config.yazi.start_dir", { clear = true }),
  callback = update_yazi_start_dir,
})

require("yazi").setup({
  open_for_directories = true,
  floating_window_scaling_factor = {
    width = 0.9,
    height = 0.6,
  },
  yazi_floating_window_border = "none",
  highlight_hovered_buffers_in_same_directory = false,
  -- Preserve the mappings from ~/.config/yazi instead of intercepting
  -- keys such as Ctrl-Q, Ctrl-Y, and Tab inside the terminal buffer.
  keymaps = false,
})

vim.keymap.set({ "n", "v" }, "<C-o>", "<Cmd>Yazi<CR>", { silent = true, desc = "Open Yazi at the current file" })
