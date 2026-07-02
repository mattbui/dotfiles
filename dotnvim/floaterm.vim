let g:floaterm_opener = 'edit'
let g:floaterm_width = 0.8


function! s:floaterm_enter() abort
  if !s:is_current_floaterm_floating()
    return
  endif

  let &laststatus = g:popup_laststatus
  autocmd! FloatermAutocmd BufWinLeave <buffer>
  autocmd FloatermAutocmd BufWinLeave <buffer> call <SID>floaterm_leave()
endfunction

function! s:floaterm_leave() abort
  let &laststatus = g:default_laststatus
endfunction

augroup FloatermAutocmd
  autocmd!
  autocmd FileType floaterm setlocal nonumber norelativenumber | call <SID>floaterm_enter()
  autocmd BufWinEnter * if &filetype ==# 'floaterm' | call <SID>floaterm_enter() | endif
augroup END

function! s:is_current_floaterm_floating() abort
  if exists('*nvim_win_get_config')
    return get(nvim_win_get_config(0), 'relative', '') !=# ''
  endif
  return getbufvar(bufnr('%'), 'floaterm_wintype', '') ==# 'float'
endfunction

function! s:floaterm_hide_and_navigate(direction) abort
  let l:floaterm_bufnr = bufnr('%')
  if s:is_current_floaterm_floating()
    call floaterm#window#hide(l:floaterm_bufnr)
  endif
  execute 'TmuxNavigate' . a:direction
endfunction

" Key mappings for floaterm
nnoremap   <silent>   <C-t>        :FloatermToggle<CR>
tnoremap   <silent>   <C-t>        <C-\><C-n>:FloatermToggle<CR>
tnoremap   <silent>   <C-n>        <C-\><C-n>:FloatermNew<CR>
tnoremap   <silent>   <M-Tab>      <C-\><C-n>:FloatermNext<CR>
tnoremap   <silent>   <Esc><Esc>   <C-\><C-n>

" When trigger tmux/vim navigation with ctrl+hjkl, hide floating floaterms first
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-h> <C-\><C-n>:call <SID>floaterm_hide_and_navigate('Left')<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-j> <C-\><C-n>:call <SID>floaterm_hide_and_navigate('Down')<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-k> <C-\><C-n>:call <SID>floaterm_hide_and_navigate('Up')<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-l> <C-\><C-n>:call <SID>floaterm_hide_and_navigate('Right')<CR>
autocmd  FileType floaterm nnoremap <buffer> <silent> <C-h> :call <SID>floaterm_hide_and_navigate('Left')<CR>
autocmd  FileType floaterm nnoremap <buffer> <silent> <C-j> :call <SID>floaterm_hide_and_navigate('Down')<CR>
autocmd  FileType floaterm nnoremap <buffer> <silent> <C-k> :call <SID>floaterm_hide_and_navigate('Up')<CR>
autocmd  FileType floaterm nnoremap <buffer> <silent> <C-l> :call <SID>floaterm_hide_and_navigate('Right')<CR>
