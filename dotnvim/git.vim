" Workaround for using gpg sign
function! GitCommit()
  call inputsave()
  let message = input("Commit message: ")
  call inputrestore()
  execute('FloatermNew! --autoclose=2 git commit -m "'.message.'" && exit')
endfunction

command! Gcommit call GitCommit()
nnoremap <leader>gc :Gcommit<cr>

" Call both coc git refresh & fugitive refresh
function! GitRefresh()
  execute("CocCommand git.refresh")
  call fugitive#ReloadStatus()
endfunction
command! Grefresh call GitRefresh()
nnoremap <silent> <leader>gr :Grefresh<cr>
