let g:minimap_width = 10
let g:minimap_auto_start=1
let g:minimap_auto_start_win_enter = 1
let g:minimap_close_filetypes = ['vim-plug', 'fugitive',  'fugitiveblame', 'coc-explorer', 'git', 'help',]
let g:minimap_close_buftypes = ['terminal']
let g:minimap_highlight_range = 1

augroup MinimapAutoCmd
  autocmd!
  autocmd VimLeavePre * execute("bw ".bufnr("-MINIMAP"))
  autocmd FileType qf wincmd J " Workaround for open quickfix with minimap
augroup END

let g:minimap_highlight = 'MinimapCurrentLine'
