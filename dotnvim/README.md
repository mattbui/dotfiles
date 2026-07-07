# dotnvim

Personal Neovim config, currently targeting Neovim 0.12+ and native `vim.pack`.

Local baseline recorded on 2026-07-04:

- `nvim --version`: `NVIM v0.12.3`

## Layout

- `init.lua`: entrypoint and module load order.
- `lua/options.lua`, `lua/filetypes.lua`, `lua/keymaps.lua`, `lua/autocmds.lua`: core editor behavior.
- `lua/plugins.lua`: `vim.pack` plugin specs and small inline plugin setup.
- `lua/plugins/`: plugin configuration modules.
- `lua/plugins/lsp/`: native LSP setup, diagnostics, mappings, and symbols.
- `lua/commands/`: custom user commands.
- `lf.vim`, `floaterm.vim`, `ipynb.vim`: remaining Vimscript integrations kept intentionally for now.

## Plugin Management

Plugins are declared through `vim.pack.add()` in `lua/plugins.lua`.

Useful commands:

- `:PackList`: list managed plugins.
- `:PackInspect`: inspect current pack state without fetching updates.
- `:PackUpdate [plugin...]`: check for updates and open the confirmation UI.
- `:PackUpdate! [plugin...]`: update immediately.
- `:PackRestore [plugin...]`: restore from `nvim-pack-lock.json` in offline lockfile mode.
- `:PackPrune! [plugin...]`: delete inactive plugins.
- `:PackLog`: open the `vim.pack` update log.

`fff.nvim` builds its native backend after install/update through a `PackChanged` hook in `lua/plugins.lua`.

## External Tools

Language servers and formatters are managed outside Neovim:

- Python LSP/lint: `basedpyright`, `ruff`
- TypeScript LSP: `typescript-language-server`
- Lua LSP: `lua-language-server`
- Formatting: `prettier`, plus project-local `.venv/bin/isort` and `.venv/bin/black` when available

The formatter config lives in `lua/plugins/autoformat.lua`; format-on-save is controlled by the visible `autoformat.format_on_save` flag.

## Main Workflows

- File picker: `fff.nvim` through `:Files`, `:Rg`, `<C-p>`, and `<C-g>`.
- Completion: `blink.cmp`.
- LSP: native `vim.lsp.config()` and `vim.lsp.enable()`.
- Formatting: `conform.nvim` through `:Format` and `<leader>cf`.
- Git: Fugitive commands plus `gitsigns.nvim` hunk actions.
- File manager and terminal: `lf.vim` and `vim-floaterm`.
- UI: `lualine.nvim`, `barbar.nvim`, `which-key.nvim`, and `tokyonight.nvim`.
