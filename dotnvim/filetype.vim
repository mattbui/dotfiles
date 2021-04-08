au BufRead,BufNewFile lfrc setlocal filetype=sh
au BufRead,BufNewFile direnvrc setlocal filetype=sh

" Filetype specific settings
autocmd FileType html set ts=2 sw=2
autocmd FileType json set ts=2 sw=2
autocmd FileType markdown set ts=2 sw=2
autocmd FileType vim set ts=2 sw=2
