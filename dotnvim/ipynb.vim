" Configs for send code to terminal
let g:slime_target = "tmux"

" fix paste issues in ipython
let g:slime_python_ipython = 1

" always send text to the top-right pane in the current tmux tab without asking
let g:slime_default_config = {
            \ 'socket_name': get(split($TMUX, ','), 0),
            \ 'target_pane': '{top-right}' }
let g:slime_dont_ask_default = 1

let g:ipython_cell_tag = ['# %%', '#%%', '# <codecell>']
let g:ipython_cell_insert_tag = '# %%'

function IPynbMappings()
  nnoremap <buffer> <silent> <leader><cr> :IPythonCellExecuteCellVerboseJump<CR>
  nmap <buffer> <cr> <Plug>SlimeLineSend
  xmap <buffer> <cr> <Plug>SlimeRegionSend
endfunction

function IPynbStart()
  call system('tmux split-window -fh -p 40 -c '. '"' . expand('%:p:h') . '"')
  silent execute('SlimeSend1 ipython')
  call system('tmux last-pane')
endfunction

function IPynbAutoReload()
  silent execute('SlimeSend1 %load_ext autoreload')
  silent execute('SlimeSend1 %autoreload 2')
endfunction

let g:jupytext_fmt = 'py:percent'
let s:cell_markers = '\"\"\"'
let s:update_meta = '{"jupytext": {"cell_markers": "' . s:cell_markers . '"}}'
let g:jupytext_opts = '--update-metadata ' . "'" . s:update_meta . "'"

autocmd FileType python if len(get(b:, 'jupytext_file', '')) > 0 | call IPynbMappings() | endif
