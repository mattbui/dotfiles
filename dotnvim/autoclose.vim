" Autoclose stuffs if they're the only window in the screen

" Autolose coc-explorer
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'coc-explorer') | 
        \if (len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) > 1) | bw | 
        \else | q | 
        \endif | 
      \endif

" Autoclose floaterm
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'floaterm') | bw! | endif

" Autoclose fugitive
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'fugitive') | bw | endif
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'fugitiveblame') | bw | endif
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'git') | bw | endif

" Autoclose qf
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'qf') | bw | endif

" Autoclose help
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'help') | bw | endif
