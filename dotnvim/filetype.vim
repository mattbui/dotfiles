au BufRead,BufNewFile lfrc setlocal filetype=sh
au BufRead,BufNewFile direnvrc setlocal filetype=sh

" Filetype specific settings
autocmd FileType html setlocal ts=2 sw=2
autocmd FileType yaml setlocal ts=2 sw=2
autocmd FileType json setlocal ts=2 sw=2
autocmd FileType typescript setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType markdown setlocal ts=2 sw=2
autocmd FileType vim setlocal ts=2 sw=2 foldmethod=marker
