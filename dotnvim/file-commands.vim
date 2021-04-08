function! NewFile()
  call inputsave()
  let filepath = input("New file: ", expand('%:h')."/")
  call inputrestore()
  execute 'edit '.filepath
endfunction
nnoremap <silent> <c-n> :call NewFile()<cr>

function! RenameFile()
  call inputsave()
  let filename = input("Rename file: ", expand('%:t'))
  call inputrestore()
  execute 'Rename '.filename
endfunction
nnoremap <silent> <leader>R :call RenameFile()<cr>

nnoremap <silent> <leader>D :Delete<cr>

command! -nargs=* Md :Mkdir <args>
function! NewDirectory()
  call inputsave()
  let directory = input("New directory: ", expand('%:h')."/")
  call inputrestore()
  execute 'Md '.directory
endfunction
nnoremap <silent> <leader>N :call NewDirectory()<cr>

function! Diff(bang)
  if a:bang
    diffoff
  else
    windo diffthis
  endif
endfunction
" Call :Diff to compare files in splits/windows
" Call :Diff! to turn off diffs
command! -bang Diff call Diff(<bang>0)
