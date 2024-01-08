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

function ApplyCustomColors()
  if g:colors_name == 'nord'
    source $HOME/.config/nvim/nord-colors.vim
  elseif (g:colors_name == 'edge' && &background =='light')
    source $HOME/.config/nvim/edge-light-colors.vim
  elseif (g:colors_name == 'tokyonight')
    hi BufferCurrentSign ctermfg=110 guifg=#bb9af7
    hi BufferCurrentTarget ctermfg=110 guifg=#bb9af7
    hi BufferInactiveTarget ctermbg=238 ctermfg=110 guibg=#3b4261 guifg=#bb9af7
    hi BufferVisibleTarget ctermbg=240 ctermfg=110 guibg=#3b4261 guifg=#bb9af7 

    hi BufferVisible guifg=#636a8d guibg=#292e42
    hi BufferVisibleINFO guifg=#0db9d7 guibg=#292e42
    hi BufferVisibleWARN guifg=#e0af68 guibg=#292e42
    hi BufferVisibleERROR guifg=#db4b4b guibg=#292e42
    hi BufferVisibleSign guifg=#636a8d guibg=#292e42

    hi BufferInactive guifg=#636a8d guibg=#292e42
    hi BufferInactiveINFO guifg=#0db9d7 guibg=#292e42
    hi BufferInactiveWARN guifg=#e0af68 guibg=#292e42
    hi BufferInactiveERROR guifg=#db4b4b guibg=#292e42
    hi BufferInactiveSign guifg=#292e42 guibg=#292e42
  endif

  hi link BufferCurrentMod BufferCurrent
  hi link BufferCurrentIcon BufferCurrent
  " hi link BufferVisibleMod BufferVisible
  " hi link BufferVisibleIcon BufferVisible
  " hi link BufferInactiveMod BufferInactive
  " hi link BufferInactiveIcon BufferInactive
  " hi link BufferAlternateMod BufferAlternate
  " hi link BufferAlternateIcon BufferAlternate

  autocmd TextChanged,TextChangedI,BufWritePost,FileWritePost,BufEnter,ColorScheme * if &modified | hi link BufferCurrentIcon BufferCurrentMod | else | hi link BufferCurrentIcon BufferCurrent | endif
endfunction

autocmd VimEnter,ColorScheme * call ApplyCustomColors()

colorscheme tokyonight-storm
