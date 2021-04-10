function! GitStatus() abort
  let status = FugitiveHead()
  return empty(status) ?  "" : " ".status
endfunction

function! CloseAll(...)
  try
    %bw
  catch
    echohl ErrorMsg
    echom v:exception
    echohl None
  endtry
endfunction

function! NerdFontReadonly()
  return &ft !~? 'help' && &readonly ? ' ' : ''
endfunction

function! NerdFontModified()
  return &modifiable && &modified ? ' ' : ''
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
      \ 'component': {
      \   'close': '%@CloseAll@  %'
      \ },
      \ 'component_function': {
      \   'gitstatus': 'GitStatus',
      \   'nerdfont_readonly': 'NerdFontReadonly',
      \   'nerdfont_modified': 'NerdFontModified'
      \ },
      \ 'tabline': {
      \   'left': [ ['buffers'] ],
      \   'right': [ ['close'] ]
      \ },
      \ 'component_expand': {
      \   'buffers': 'lightline#bufferline#buffers'
      \ },
      \ 'component_type': {
      \   'buffers': 'tabsel'
      \ }
      \ }

call lightline#coc#register()

let g:lightline#bufferline#enable_devicons = 1
let g:lightline#bufferline#icon_position = 'left'
let g:lightline#bufferline#unnamed = 'unnamed'
let g:lightline#bufferline#modified = ' '
let g:lightline#bufferline#read_only = ' '
let g:lightline#bufferline#more_buffers = '  '

" make tabline clickable
let g:lightline#bufferline#clickable = 1
let g:lightline.component_raw = {'buffers': 1}

nmap <Leader>1 <Plug>lightline#bufferline#go(1)
nmap <Leader>2 <Plug>lightline#bufferline#go(2)
nmap <Leader>3 <Plug>lightline#bufferline#go(3)
nmap <Leader>4 <Plug>lightline#bufferline#go(4)
nmap <Leader>5 <Plug>lightline#bufferline#go(5)
nmap <Leader>6 <Plug>lightline#bufferline#go(6)
nmap <Leader>7 <Plug>lightline#bufferline#go(7)
nmap <Leader>8 <Plug>lightline#bufferline#go(8)
nmap <Leader>9 <Plug>lightline#bufferline#go(9)
nmap <Leader>0 <Plug>lightline#bufferline#go(10)
