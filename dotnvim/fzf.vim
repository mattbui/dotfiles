let g:fzf_layout = { 'window': { 'width': 0.6, 'height': 0.6 } }


function! s:fzf_enter() abort
  let &laststatus = g:popup_laststatus
  autocmd! FzfAutocmd BufWinLeave <buffer>
  autocmd FzfAutocmd BufWinLeave <buffer> call <SID>fzf_leave()
endfunction

function! s:fzf_leave() abort
  let &laststatus = g:default_laststatus
endfunction

augroup FzfAutocmd
  autocmd!
  autocmd FileType fzf call <SID>fzf_enter()
augroup END

map <silent> <C-p> :Files<CR>

" search global
map <silent> <C-g> :Rg<CR>

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
