local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.g.python3_host_prog = vim.fs.joinpath(vim.fn.stdpath("data"), "python3", "bin", "python")

local function source_config(name)
  vim.cmd.source(config_dir .. "/" .. name)
end

-- General settings
require("ui2")
require("options")
require("filetypes")
require("keymaps")
require("autocmds")
require("commands")
require("autobuffers")

-- Plugins configs
require("plugins")
require("plugins.yazi")
require("plugins.gitsigns")
require("plugins.lsp")
require("plugins.autoformat")
require("plugins.completion")
require("plugins.pickers")
require("plugins.ipython")
require("plugins.barbar")
require("plugins.which_key")
require("plugins.mini")
require("plugins.indent_blankline")
require("plugins.neoscroll")
require("plugins.treesitter")
source_config("floaterm.vim")

-- Theme configs
require("colorscheme")

-- Load after tokyonight to set the correct style
require("plugins.lualine")
