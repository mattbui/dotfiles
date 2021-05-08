if (has("termguicolors"))
  set termguicolors
endif

" let ayucolor="light"
" let g:wwdc17_frame_color=15

" colorscheme ayu
" colorscheme onehalflight
" colorscheme wwdc17
let g:edge_disable_italic_comment = 1
let g:edge_enable_italic = 1
colorscheme edge

" Minimap colors
hi MinimapCurrentLine ctermfg=134 ctermbg=255 guibg=#eef1f4 guifg=#b05ccc

let g:minimap_highlight = 'MinimapCurrentLine'

" Indent guid colors
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd guibg=#f4f6f8
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#f1f3f6

" Tabbar colors
hi BufferCurrentSign ctermfg=134 guifg=#bf75d6
hi link BufferCurrentMode BufferCurrent
hi link BufferVisibleMod BufferVisible
hi link BufferInactiveMod BufferInactive

hi BufferCurrentTarget cterm=italic ctermfg=134 gui=italic guifg=#b05ccc
hi BufferInactiveTarget cterm=italic ctermbg=255 ctermfg=134 gui=italic guibg=#eef1f4 guifg=#b05ccc
hi BufferVisibleTarget cterm=italic ctermbg=231 ctermfg=134 gui=italic guibg=#bf75d6 guifg=#fafafa 

autocmd TextChanged,TextChangedI,BufWritePost,FileWritePost,BufEnter * if &modified | hi link BufferCurrentIcon BufferCurrentMod | else | hi link BufferCurrentIcon BufferCurrent | endif
