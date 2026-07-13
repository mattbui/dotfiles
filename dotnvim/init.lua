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
-- Load the colorscheme before plugins derive their highlights.
require("colorscheme")

require("plugins.yazi")
require("plugins.gitsigns")
require("plugins.lsp")
require("plugins.autoformat")
require("plugins.completion")
require("plugins.pickers")
require("plugins.ipython")
require("plugins.barbar")
require("plugins.which-key")
require("plugins.mini")
require("plugins.indent-blankline")
require("plugins.neoscroll")
require("plugins.treesitter")
require("plugins.floaterm")
require("plugins.lualine")
