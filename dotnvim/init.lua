vim.g.python3_host_prog = vim.fs.joinpath(vim.fn.stdpath("data"), "python3", "bin", "python")

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
require("plugins.floaterm")

-- Theme configs
require("colorscheme")

-- Load after tokyonight to set the correct style
require("plugins.lualine")
