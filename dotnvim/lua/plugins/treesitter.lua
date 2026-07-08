local treesitter = require("nvim-treesitter")

require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true,
    selection_modes = {
      ["@class.outer"] = "V",
      ["@function.outer"] = "V",
    },
  },
  move = {
    set_jumps = true,
  },
})

local ts_select = require("nvim-treesitter-textobjects.select")
local ts_move = require("nvim-treesitter-textobjects.move")
local map = vim.keymap.set

map({ "x", "o" }, "am", function()
  ts_select.select_textobject("@function.outer", "textobjects")
end, { desc = "Around method/function" })

map({ "x", "o" }, "im", function()
  ts_select.select_textobject("@function.inner", "textobjects")
end, { desc = "Inside method/function" })

map({ "x", "o" }, "ac", function()
  ts_select.select_textobject("@class.outer", "textobjects")
end, { desc = "Around class" })

map({ "x", "o" }, "ic", function()
  ts_select.select_textobject("@class.inner", "textobjects")
end, { desc = "Inside class" })

map({ "n", "x", "o" }, "gm", function()
  ts_move.goto_next_start("@function.outer", "textobjects")
end, { desc = "Next method/function" })

map({ "n", "x", "o" }, "gM", function()
  ts_move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "Previous method/function" })

pcall(vim.keymap.del, "n", "gcc")

map({ "n", "x", "o" }, "gc", function()
  ts_move.goto_next_start("@class.outer", "textobjects")
end, { desc = "Next class" })

map({ "n", "x", "o" }, "gC", function()
  ts_move.goto_previous_start("@class.outer", "textobjects")
end, { desc = "Previous class" })

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
