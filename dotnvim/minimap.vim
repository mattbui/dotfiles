let g:minimap_width = 10
let g:minimap_auto_start = 1
let g:minimap_auto_start_win_enter = 1
let g:minimap_close_filetypes = ['vim-plug', 'fugitive',  'fugitiveblame', 'coc-explorer', 'git', 'help', 'fzf']
let g:minimap_highlight_range = 1

hi MinimapCurrentLine ctermfg=134 ctermbg=255 guibg=#eef1f4 guifg=#b05ccc

let g:minimap_highlight = 'MinimapCurrentLine'

autocmd WinClosed * MinimapClose
