local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")

local function source_config(name)
  vim.cmd.source(config_dir .. "/" .. name)
end

-- General settings
require("ui2")
require("options")
require("filetypes")
require("keymaps")
require("autocmds")
require("commands.yank_path")
require("autobuffers")

-- Plugins configs
require("plugins")
require("commands.pack")
require("plugins.gitsigns")
require("plugins.lsp")
require("plugins.autoformat")
require("plugins.completion")
require("commands.git")
require("plugins.fff")

source_config("lf.vim")
source_config("floaterm.vim")

require("plugins.ipython")
require("plugins.barbar")
require("plugins.which_key")
require("plugins.mini")
require("plugins.indent-blankline")
require("plugins.lualine")
require("plugins.neoscroll")
require("plugins.treesitter")

-- Theme configs
require("colorscheme")
