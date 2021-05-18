" Configs for send code to terminal
let g:slime_target = "tmux"

" fix paste issues in ipython
let g:slime_python_ipython = 1

" always send text to the top-right pane in the current tmux tab without asking
let g:slime_default_config = {
            \ 'socket_name': get(split($TMUX, ','), 0),
            \ 'target_pane': '{top-right}' }
let g:slime_dont_ask_default = 1

let g:ipython_cell_insert_tag = '# %%'

function IPynbMappings()
  nnoremap <buffer> <silent> <leader><cr> :IPythonCellExecuteCellVerboseJump<CR>
  nmap <buffer> <cr> <Plug>SlimeLineSend
  xmap <buffer> <cr> <Plug>SlimeRegionSend
endfunction

function IPynbStart()
  call system('tmux split-window -fh -l 80 -c '. '"' . expand('%:p:h') . '"')
  silent execute('SlimeSend1 ipython')
  call system('tmux last-pane')
endfunction

function IPynbClose()
  " Exit ipython and exit tmux window
  silent execute('SlimeSend1 exit')
  silent execute('SlimeSend1 exit')
endfunction

autocmd FileType python if get(b:, 'ipynb_on', 0) is 1 | call IPynbMappings() | endif
