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

let g:lightline = {
      \ 'colorscheme': 'edge',
      \ 'active': {
      \   'left': [
      \           ['mode',      'paste' ],
      \           ['gitstatus', 'nerdfont_readonly', 'filename', 'nerdfont_modified' ],
      \           ['coc_info',  'coc_hints', 'coc_errors', 'coc_warnings', 'coc_ok' ],
      \           ['coc_status' ]
      \           ],
      \   'right':[
      \           ['lineinfo' ],
      \           ['percent' ],
      \           ['fileformat', 'fileencoding', 'filetype' ],
      \           ]
      \ },
      \ 'component_function': {
      \   'gitstatus': 'GitStatus',
      \   'nerdfont_readonly': 'NerdFontReadonly',
      \   'nerdfont_modified': 'NerdFontModified'
      \ },
      \ 'tabline': {},
      \ }

call lightline#coc#register()
