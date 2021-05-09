" Mimimap colors {{{
hi MinimapCurrentLine ctermfg=134 ctermbg=255 guibg=#eef1f4 guifg=#b05ccc
" }}}

" Indent guide colors {{{
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd guibg=#f4f6f8
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#f1f3f6
" }}}

" Tabbar colors {{{
hi BufferCurrentSign ctermfg=134 guifg=#bf75d6
hi BufferCurrentTarget cterm=italic ctermfg=134 gui=italic guifg=#b05ccc
hi BufferInactiveTarget cterm=italic ctermbg=255 ctermfg=134 gui=italic guibg=#eef1f4 guifg=#b05ccc
hi BufferVisibleTarget cterm=italic ctermbg=231 ctermfg=134 gui=italic guibg=#bf75d6 guifg=#fafafa 
hi link BufferCurrentMod BufferCurrent
" }}}
