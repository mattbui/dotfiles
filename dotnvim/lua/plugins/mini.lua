require("mini.pairs").setup()

require("mini.ai").setup({
  n_lines = 1000,
  mappings = {
    -- don't need these, also avoid override neovim >= 0.12's default an/in behavior
    around_next = "",
    inside_next = "",
    around_last = "",
    inside_last = "",
  }

})
require("mini.align").setup({
  mappings = {
    start = "",
    start_with_preview = "<Leader>a",
  },
})
require("mini.surround").setup()
require("mini.splitjoin").setup({
  mappings = {
    toggle = "",
    split = "sj",
    join = "sk",
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

local MiniSessions = require("mini.sessions")

vim.opt.sessionoptions:append("globals")

MiniSessions.setup({
  autoread = true,
  autowrite = true,
  hooks = {
    pre = {
      write = function()
        vim.cmd("argglobal")
        vim.cmd("%argdelete")
        vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
      end,
    },
    post = {
      read = function()
        do_bufread_for_restored_buffers()
        vim.schedule(function()
          require("autobuffers").mark_restored_buffers_permanent()
        end)
      end,
    },
  },
})

vim.api.nvim_create_user_command("MiniSessionEnable", function()
  MiniSessions.write()
end, { desc = "Enable a local Mini session" })

local MiniIndentScope = require("mini.indentscope")

MiniIndentScope.setup({
  draw = {
    animation = MiniIndentScope.gen_animation.none(),
    delay = 0,
  },
  mappings = {
    object_scope = "ii",
    object_scope_with_border = "ai",
    goto_bottom = "gi",
    goto_top = "gI",
  },
  options = {
    try_as_border = false,
  },
  symbol = "▏",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MiniIndentscopePython", { clear = true }),
  pattern = {
    "python",
    "yaml",
  },
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
    "checkhealth",
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
