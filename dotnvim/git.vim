" Workaround for using gpg sign
function! GitCommit()
  call inputsave()
  let message = input("Commit message: ")
  call inputrestore()
  execute('FloatermNew! --autoclose=2 git commit -m "'.message.'" && exit')
endfunction

command! Gcommit call GitCommit()

" Call both coc git refresh & fugitive refresh
function! GitRefresh()
  execute("CocCommand git.refresh")
  call fugitive#ReloadStatus()
endfunction
command! Grefresh call GitRefresh()

function! GitChangeBranch()
  call inputsave()
  let branch = input("Change to branch: ")
  call inputrestore()
  redraw
  execute('Git checkout '.branch)
endfunction

function! GitNewBranch()
  call inputsave()
  let new_branch = input("Create new branch: ")
  call inputrestore()
  call inputsave()
  let old_branch = input("From old branch: ")
  call inputrestore()
  if empty(old_branch)
    let old_branch = "".fugitive#head()
  endif
  redraw
  execute("Git checkout -b ".new_branch." ".old_branch)
endfunction
