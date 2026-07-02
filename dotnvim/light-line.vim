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

function! SmartPath() abort
  let path = expand('%:.')
  if empty(path)
    return '[No Name]'
  endif

  let threshold = max([20, float2nr(winwidth(0) * 0.35)])
  if strdisplaywidth(path) <= threshold
    return path
  endif

  let parts = split(path, '/')
  if len(parts) <= 1
    return path
  endif

  let parent_lengths = [6, 4, 2, 1]
  let shortened = []
  for i in range(0, len(parts) - 2)
    let distance_from_file = len(parts) - i - 1
    let length_index = min([distance_from_file - 1, len(parent_lengths) - 1])
    let shortened += [strcharpart(parts[i], 0, parent_lengths[length_index])]
  endfor
  let shortened += [parts[-1]]

  return join(shortened, '/')
endfunction

let g:lightline = {
      \ 'colorscheme': 'tokyonight',
      \ 'active': {
      \   'left': [
      \           ['mode', 'paste'],
      \           ['gitstatus', 'nerdfont_readonly', 'smartpath', 'nerdfont_modified', 'tagbar'],
      \           ['coc_info', 'coc_hints', 'coc_errors', 'coc_warnings', 'coc_ok'],
      \           ['coc_status'],
      \           ],
      \   'right':[
      \           [],
      \           ['cursorinfo', 'percent'],
      \           ['fileformat', 'fileencoding', 'filetype'],
      \           ]
      \ },
      \ 'inactive': {
      \   'left': [
      \           ['mode', 'paste'],
      \           ],
      \   'right':[]
      \ },
      \ 'enable': {
      \   'tabline': 0
      \ },
      \ 'component_function': {
      \   'cursorinfo': "CursorInfo",
      \   'gitstatus': 'GitStatus',
      \   'nerdfont_readonly': 'NerdFontReadonly',
      \   'nerdfont_modified': 'NerdFontModified',
      \   'smartpath': 'SmartPath',
      \ },
      \ 'component':{
      \   'relativepath': '%<%f',
      \   'tagbar': '%<%{tagbar#currenttag("[%s]", "", "f")}',
      \ }
      \ }

call lightline#coc#register()
