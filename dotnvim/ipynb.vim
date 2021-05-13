" Configs for send code to terminal
let g:slime_target = "tmux"

" fix paste issues in ipython
let g:slime_python_ipython = 1

" always send text to the top-right pane in the current tmux tab without asking
let g:slime_default_config = {
            \ 'socket_name': get(split($TMUX, ','), 0),
            \ 'target_pane': '{top-right}' }
let g:slime_dont_ask_default = 1

function IPynbMappings()
  nnoremap <buffer> <silent> <leader><cr> :IPythonCellExecuteCellJump<CR>
  nmap <buffer> <cr> <Plug>SlimeLineSend
  xmap <buffer> <cr> <Plug>SlimeRegionSend
endfunction

autocmd FileType python if get(b:, 'ipynb_on', 0) is 1 | call IPynbMappings() | endif
