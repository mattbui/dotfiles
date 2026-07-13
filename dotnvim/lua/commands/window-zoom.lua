local function window_zoom_toggle()
  if vim.fn.winnr("$") == 1 then
    return
  end

  if vim.t.window_zoom_restore then
    vim.cmd(vim.t.window_zoom_restore)
    vim.t.window_zoom_restore = nil
    return
  end

  vim.t.window_zoom_restore = vim.fn.winrestcmd()
  vim.cmd("wincmd _")
  vim.cmd("wincmd |")
end

vim.api.nvim_create_user_command("WindowZoomToggle", window_zoom_toggle, {
  desc = "Maximize or restore the current split",
})

vim.keymap.set("n", "<Leader>wz", "<Cmd>WindowZoomToggle<CR>", { silent = true, desc = "Zoom current" })
vim.keymap.set("n", "<Leader>Z", "<Cmd>WindowZoomToggle<CR>", { silent = true, desc = "Zoom current" })
