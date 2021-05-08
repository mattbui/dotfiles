" Move to previous/next
nnoremap <silent> <S-k> :BufferPrevious<CR>
nnoremap <silent> <S-j> :BufferNext<CR>

" Re-order buffers
nnoremap <silent> <S-l> :BufferMoveNext<CR>
nnoremap <silent> <S-h> :BufferMovePrevious<CR>

" Goto buffer in position...
nnoremap <silent> <leader>1 :BufferGoto 1<CR>
nnoremap <silent> <leader>2 :BufferGoto 2<CR>
nnoremap <silent> <leader>3 :BufferGoto 3<CR>
nnoremap <silent> <leader>4 :BufferGoto 4<CR>
nnoremap <silent> <leader>5 :BufferGoto 5<CR>
nnoremap <silent> <leader>6 :BufferGoto 6<CR>
nnoremap <silent> <leader>7 :BufferGoto 7<CR>
nnoremap <silent> <leader>8 :BufferGoto 8<CR>
nnoremap <silent> <leader>9 :BufferGoto 9<CR>
nnoremap <silent> <leader>0 :BufferLast<CR>

" Magic buffer-picking mode
nnoremap <silent> <leader>p :BufferPick<CR>

" NOTE: If barbar's option dict isn't created yet, create it
let bufferline = get(g:, 'bufferline', {})

" Enable/disable current/total tabpages indicator (top right corner)
let bufferline.tabpages = v:false

" Sets the icon's highlight group.
" If false, will use nvim-web-devicons colors
let bufferline.icon_custom_colors = v:true

" Configure icons on the bufferline.
let bufferline.icon_separator_active = '▎'
let bufferline.icon_separator_inactive = '▏'

hi BufferCurrentSign ctermfg=134 guifg=#bf75d6
hi link BufferVisibleMod BufferVisible
hi link BufferInactiveMod BufferInactive

hi BufferCurrentTarget cterm=italic ctermfg=134 gui=italic guifg=#b05ccc
hi BufferInactiveTarget cterm=italic ctermbg=255 ctermfg=134 gui=italic guibg=#eef1f4 guifg=#b05ccc
hi BufferVisibleTarget cterm=italic ctermbg=231 ctermfg=134 gui=italic guibg=#bf75d6 guifg=#fafafa 

autocmd TextChanged,TextChangedI,BufWritePost,FileWritePost,BufEnter * if &modified | hi link BufferCurrentIcon BufferCurrentMod | else | hi link BufferCurrentIcon BufferCurrent | endif
