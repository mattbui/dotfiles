au BufRead,BufNewFile lfrc setlocal filetype=sh
au BufRead,BufNewFile direnvrc setlocal filetype=sh

" Filetype specific settings
autocmd FileType html ts=2 sw=2
autocmd FileType json ts=2 sw=2
