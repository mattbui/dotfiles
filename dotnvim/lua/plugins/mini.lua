require("mini.pairs").setup()
require("mini.ai").setup()
require("mini.align").setup({
  mappings = {
    start = "",
    start_with_preview = "<Leader>a",
  },
})
require("mini.surround").setup()
require("mini.splitjoin").setup({
  mappings = {
    toggle = "<Leader>ss",
    split = "<Leader>sj",
    join = "<Leader>sk",
  },
})

local function do_bufread_for_restored_buffers()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if
        vim.api.nvim_buf_is_loaded(buffer)
        and vim.api.nvim_buf_get_name(buffer) ~= ""
        and vim.bo[buffer].filetype == ""
    then
      vim.api.nvim_buf_call(buffer, function()
        vim.cmd("doautocmd BufRead")
      end)
    end
  end
end

require("mini.sessions").setup({
  autoread = true,
  autowrite = true,
  hooks = {
    pre = {
      write = function()
        vim.cmd("argglobal")
        vim.cmd("%argdelete")
      end,
    },
    post = {
      read = do_bufread_for_restored_buffers,
    },
  },
})

require("mini.notify").setup({
  content = {
    format = function(notif)
      return notif.msg
    end,
  },
  window = {
    config = { title = "" },
  },
})

local MiniIndentScope = require("mini.indentscope")

MiniIndentScope.setup({
  draw = {
    animation = MiniIndentScope.gen_animation.none(),
    delay = 0,
  },
  mappings = {
    object_scope = "is",
    object_scope_with_border = "as",
    goto_bottom = "gs",
    goto_top = "gS",
  },
  options = {
    try_as_border = false,
  },
  symbol = "▏",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MiniIndentscopePython", { clear = true }),
  pattern = "python",
  callback = function()
    local config = vim.b.miniindentscope_config or {}
    vim.b.miniindentscope_config = vim.tbl_deep_extend("force", config, {
      options = {
        -- Stop Python scopes before trailing blank lines at a dedent.
        border = "top",
      },
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MiniIndentscopeDisable", { clear = true }),
  pattern = {
    "help",
    "which_key",
    "fugitive",
    "man",
  },
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("MiniIndentscopeTerminalDisable", { clear = true }),
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
})
