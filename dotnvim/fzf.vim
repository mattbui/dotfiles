let g:fzf_layout = { 'window': { 'width': 0.6, 'height': 0.6 } }

map <silent> <C-p> :Files<CR>
" search in current buffer
map <silent> <C-f> :BLines<CR>
" search global
map <silent> <C-g> :Rg<CR>

nnoremap <silent> <Tab> :Buffers<CR>

autocmd FileType fzf tnoremap <buffer> <Tab> <C-n>
autocmd FileType fzf tnoremap <buffer> <S-TAB> <C-p>
autocmd FileType fzf tnoremap <buffer> * <Tab>

command! -bang -nargs=? -complete=dir Files call fzf#vim#files(<q-args>, <bang>0)
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
  \   <bang>0)

let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }
