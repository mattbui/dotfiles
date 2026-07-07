local treesitter = require("nvim-treesitter")

local ensure_installed = {
  "python",
  "typescript",
  "javascript",
  "tsx",
  "html",
  "css",
  "json",
  "bash",
  "http",
  "dockerfile",
  "toml",
  "yaml",
}

vim.api.nvim_create_user_command("TSInstallDefaults", function()
  treesitter.install(ensure_installed)
end, {})

local function start_treesitter(buffer)
  if not vim.api.nvim_buf_is_loaded(buffer) or vim.bo[buffer].filetype == "" then
    return
  end

  pcall(vim.treesitter.start, buffer)
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    start_treesitter(args.buf)
  end,
})

for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
  start_treesitter(buffer)
end
