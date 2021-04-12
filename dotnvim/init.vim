" General settings
source $HOME/.config/nvim/settings.vim
source $HOME/.config/nvim/filetype.vim
source $HOME/.config/nvim/mappings.vim

" Plugins configs
source $HOME/.config/nvim/polygot.vim
source $HOME/.config/nvim/plugins.vim

source $HOME/.config/nvim/autoclose.vim
source $HOME/.config/nvim/coc.vim
source $HOME/.config/nvim/light-line.vim
source $HOME/.config/nvim/tmux-line.vim
source $HOME/.config/nvim/fzf.vim
source $HOME/.config/nvim/rooter.vim
source $HOME/.config/nvim/lf.vim
source $HOME/.config/nvim/floaterm.vim
source $HOME/.config/nvim/commentary.vim
source $HOME/.config/nvim/start-screen.vim
source $HOME/.config/nvim/which-key.vim
source $HOME/.config/nvim/easy-align.vim
source $HOME/.config/nvim/markdown-preview.vim
source $HOME/.config/nvim/markdown-toc.vim
source $HOME/.config/nvim/snippets.vim
source $HOME/.config/nvim/pydocstring.vim
source $HOME/.config/nvim/file-commands.vim
source $HOME/.config/nvim/git.vim
source $HOME/.config/nvim/indent-guide.vim

" Theme configs
source $HOME/.config/nvim/colorscheme.vim
" source $HOME/.config/nvim/indent-line.vim

lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ignore_install = {}, -- List of parsers to ignore installing
  highlight = {
    enable = true,              -- false will disable the whole extension
    disable = {},  -- list of language that will be disabled
  },
}
EOF
