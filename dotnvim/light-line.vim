function! GitStatus() abort
  let status = get(g:, 'coc_git_status', '')
  return status
endfunction

let g:lightline = {
      \ 'colorscheme': 'edge',
      \ 'active': {
      \   'left': [ [ 'mode',      'paste' ],
      \             [ 'gitstatus', 'readonly', 'filename', 'modified' ],
      \             [ 'coc_info',  'coc_hints', 'coc_errors', 'coc_warnings', 'coc_ok' ],
      \             [ 'coc_status' ]
      \           ],
      \ },
      \ 'component_function': {
      \   'gitstatus': 'GitStatus'
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

let g:lightline#bufferline#show_number = 2
let g:lightline#bufferline#enable_devicons = 1
let g:lightline#bufferline#icon_position = 'right'
let g:lightline#bufferline#unnamed = 'unnamed'

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
