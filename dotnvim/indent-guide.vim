let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_auto_colors = 0
" let g:indent_guides_guide_size = 1
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd guibg=#f4f6f8
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#f1f3f6
