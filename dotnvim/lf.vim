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
  call timer_start(5, {-> chansend(l:job, ":clear\<CR>:unselect\<CR>")})
endfunction

function! s:QuitLfFloaterm() abort
  if !s:IsLfFloaterm() || !exists('b:terminal_job_id')
    return
  endif

  " Send lf its own <c-q> key instead of typing `:quit` into the UI.  This
  " keeps the quit path in lfrc (`map <c-q> quit`) and avoids interacting with
  " any other lf mappings such as <space>.
  call chansend(b:terminal_job_id, nr2char(17))
endfunction

function! s:SetupLfFloaterm() abort
  if !s:IsLfFloaterm()
    return
  endif

  nnoremap <buffer> <silent> <C-q> :<C-u>call <SID>QuitLfFloaterm()<CR>
  tnoremap <buffer> <silent> <C-q> <C-\><C-n>:call <SID>QuitLfFloaterm()<CR>

  if !get(b:, 'lf_floaterm_initialized', 0)
    let b:lf_floaterm_initialized = 1
    call s:ClearLfFloaterm()
  endif
endfunction

augroup LfFloatermKeys
  autocmd!
  " vim-floaterm reliably emits User FloatermOpen after creating/opening the
  " terminal. Keep FileType as a fallback for non-floaterm terminal creation.
  autocmd User FloatermOpen call s:SetupLfFloaterm()
  autocmd FileType floaterm call s:SetupLfFloaterm()
augroup END

nnoremap <silent> <C-o> :Lf<CR> 
