function! GitStatus() abort
  let status = FugitiveHead()
  return empty(status) ?  "" : " ".status
endfunction

function! NerdFontReadonly()
  return &ft !~? 'help' && &readonly ? '' : ''
endfunction

function! NerdFontModified()
  return &modifiable && &modified ? '●' : ''
endfunction

function! CursorInfo() abort
  return col('.') . ':' . line('.') . ' | ' . line('$')
endfunction

let g:lightline = {
      \ 'colorscheme': g:colors_name,
      \ 'active': {
      \   'left': [
      \           ['mode',      'paste' ],
      \           ['gitstatus', 'nerdfont_readonly', 'relativepath', 'nerdfont_modified', 'cursorinfo' ],
      \           ['coc_info',  'coc_hints', 'coc_errors', 'coc_warnings', 'coc_ok' ],
      \           ['coc_status' ],
      \           ],
      \   'right':[
      \           [ ],
      \           ['percent' ],
      \           ['fileformat', 'fileencoding', 'filetype' ],
      \           ]
      \ },
      \ 'enable': {
      \   'tabline': 0
      \ },
      \ 'component_function': {
      \   'cursorinfo': "CursorInfo",
      \   'gitstatus': 'GitStatus',
      \   'nerdfont_readonly': 'NerdFontReadonly',
      \   'nerdfont_modified': 'NerdFontModified',
      \ },
      \ 'component':{
      \   'relativepath': '%<%f'
      \ }
      \ }

call lightline#coc#register()
