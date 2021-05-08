if (has("termguicolors"))
  set termguicolors
endif

" let ayucolor="light"
" let g:wwdc17_frame_color=15

" colorscheme ayu
" colorscheme onehalflight
" colorscheme wwdc17
" let g:edge_disable_italic_comment = 1
" let g:edge_enable_italic = 1
" colorscheme edge
colorscheme nord

" Minimap colors
if (g:colors_name == 'edge' && &background =='light')
  hi MinimapCurrentLine ctermfg=134 ctermbg=255 guibg=#eef1f4 guifg=#b05ccc
elseif g:colors_name == 'nord'
  hi MinimapCurrentLine ctermbg=238 ctermfg=110 guibg=#3b4252 guifg=#88C0D0
endif

let g:minimap_highlight = 'MinimapCurrentLine'

" Indent guid colors
if (g:colors_name == 'edge' && &background =='light')
  autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd guibg=#f4f6f8
  autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#f1f3f6
elseif g:colors_name == 'nord'
  autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd guibg=#434C5E
  autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#4C566A
endif

" Tabbar colors
if (g:colors_name == 'edge' && &background =='light')
  hi BufferCurrentSign ctermfg=134 guifg=#bf75d6
  hi BufferCurrentTarget cterm=italic ctermfg=134 gui=italic guifg=#b05ccc
  hi BufferInactiveTarget cterm=italic ctermbg=255 ctermfg=134 gui=italic guibg=#eef1f4 guifg=#b05ccc
  hi BufferVisibleTarget cterm=italic ctermbg=231 ctermfg=134 gui=italic guibg=#bf75d6 guifg=#fafafa 
hi link BufferCurrentMod BufferCurrent
elseif g:colors_name == 'nord'
  hi BufferCurrentSign ctermfg=110 guifg=#88C0D0
  hi BufferCurrentTarget cterm=bold ctermfg=110 gui=bold guifg=#88C0D0
  hi BufferInactiveTarget cterm=bold ctermbg=238 ctermfg=110 gui=bold guibg=#3b4252 guifg=#88C0D0
  hi BufferVisibleTarget cterm=bold ctermbg=240 ctermfg=110 gui=bold guibg=#4c566a guifg=#88C0D0 
endif

hi link BufferVisibleMod BufferVisible
hi link BufferInactiveMod BufferInactive

autocmd TextChanged,TextChangedI,BufWritePost,FileWritePost,BufEnter * if &modified | hi link BufferCurrentIcon BufferCurrentMod | else | hi link BufferCurrentIcon BufferCurrent | endif
