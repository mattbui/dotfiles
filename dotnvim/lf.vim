let g:lf_map_keys = 0
let g:lf_replace_netrw = 1 " Open lf when vim opens a directory

" Detect the lf instance launched through vim-floaterm. lf.vim sets the
" floaterm title to 'lf', which lets us avoid touching other floaterms.
function! s:IsLfFloaterm() abort
  return &filetype ==# 'floaterm'
        \ && get(b:, 'floaterm_title', '') ==# 'lf'
endfunction

" Clear lf's copy/cut state and file selections shortly after the terminal
" opens. A small delay gives lf enough time to finish initializing/syncing.
function! s:ClearLfFloaterm() abort
  if !s:IsLfFloaterm() || !exists('b:terminal_job_id')
    return
  endif

  let l:job = b:terminal_job_id
  call timer_start(20, {-> chansend(l:job, ":clear\<CR>:unselect\<CR>")})
endfunction

augroup LfFloatermKeys
  autocmd!
  " lf-only buffer mappings: make <C-q> run lf's :quit command instead of
  " closing/killing the floaterm, which can produce non-zero exit code 3.
  " Also clear stale lf selection state when the lf floaterm opens.
  autocmd FileType floaterm if s:IsLfFloaterm() |
        \ nnoremap <buffer> <C-q> i:quit<CR> |
        \ tnoremap <buffer> <C-q> :quit<CR> |
        \ call s:ClearLfFloaterm() |
        \ endif
augroup END

nnoremap <silent> <C-o> :Lf<CR> 
