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

hi link BufferCurrentMod BufferCurrent
hi link BufferVisibleMod BufferVisible
hi link BufferInactiveMod BufferInactive

autocmd TextChanged,TextChangedI,BufWritePost,FileWritePost,BufEnter * if &modified | hi link BufferCurrentIcon BufferCurrentMod | else | hi link BufferCurrentIcon BufferCurrent | endif

if g:colors_name == 'nord'
  source $HOME/.config/nvim/nord-colors.vim
elseif (g:colors_name == 'edge' && &background =='light')
  source $HOME/.config/nvim/edge-light-colors.vim
endif
