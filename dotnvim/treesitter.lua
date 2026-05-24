local ok, treesitter = pcall(require, 'nvim-treesitter')

if ok then
  treesitter.setup()

  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      if vim.bo[args.buf].filetype == 'dockerfile' then
        return
      end

      pcall(vim.treesitter.start, args.buf)
    end,
  })
else
  require'nvim-treesitter.configs'.setup {
    ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    ignore_install = {"ipkg"}, -- List of parsers to ignore installing
    highlight = {
      enable = true,              -- false will disable the whole extension
      disable = {"dockerfile"},  -- list of language that will be disabled
    },
  }
end
