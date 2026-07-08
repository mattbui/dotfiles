local gh = function(repo)
  return 'https://github.com/' .. repo
end

vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('dotfiles.pack.fff', { clear = true }),
  callback = function(ev)
    local data = ev.data or {}
    local spec = data.spec or {}
    local name, kind = spec.name, data.kind
    if name == 'fff.nvim' and (kind == 'install' or kind == 'update') then
      -- Build the native backend so fff uses ripgrep instead of zlob.
      local result = vim.system({
        'cargo',
        'build',
        '--release',
        '-p',
        'fff-nvim',
      }, { cwd = data.path }):wait()

      if result.code ~= 0 then
        error('failed to build fff.nvim native backend: ' .. (result.stderr or 'unknown error'))
      end
    end
  end,
})

vim.pack.add({
  -- Terminal and file manager workflows.
  gh('ptzz/lf.vim'),
  gh('voldikss/vim-floaterm'),

  -- Minimal editing helpers.
  gh('nvim-mini/mini.nvim'),

  -- Indentation and scrolling.
  gh('lukas-reineke/indent-blankline.nvim'),
  gh('karb94/neoscroll.nvim'),

  -- Git integration.
  gh('lewis6991/gitsigns.nvim'),
  gh('tpope/vim-fugitive'),

  -- Language intelligence, completion, and formatting.
  gh('neovim/nvim-lspconfig'),
  gh('saghen/blink.lib'),
  gh('saghen/blink.cmp'),
  gh('stevearc/conform.nvim'),
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'main' },

  -- Picker.
  gh('dmtrKovalenko/fff.nvim'),

  -- UI components.
  gh('kyazdani42/nvim-web-devicons'),
  gh('romgrk/barbar.nvim'),
  gh('nvim-lualine/lualine.nvim'),
  gh('folke/which-key.nvim'),

  -- Notebook and REPL workflow.
  gh('jpalardy/vim-slime'),
  gh('hanschen/vim-ipython-cell'),
  { src = gh('mattbui/jupytext.vim'),            version = 'jupytext_opts' },

  -- tmux navigation.
  gh('christoomey/vim-tmux-navigator'),

  -- Theme.
  gh('folke/tokyonight.nvim'),

})
