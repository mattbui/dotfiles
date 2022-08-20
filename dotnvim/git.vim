let g:reload_fugitive = v:false
" Workaround for using gpg sign
function! GitCommit()
  call inputsave()
  let message = input("Commit message: ")
  call inputrestore()
  execute('FloatermNew! --autoclose=2 git commit -m "'.message.'" && exit')
  let g:reload_fugitive = v:true
endfunction

command! Gcommit call GitCommit()

" Call both coc git refresh & fugitive refresh
function! GitRefresh()
  execute("CocCommand git.refresh")
  call fugitive#ReloadStatus()
endfunction
command! Grefresh call GitRefresh()

function! GitPushCurrentBranch()
  echo "Pushing to  ".FugitiveHead()
  execute("Git -c push.default=current push")
endfunction

function! GitPull()
  echo "Pulling"
  execute("Git pull")
endfunction

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
    let old_branch = "".FugitiveHead()
  endif
  redraw
  execute("Git checkout -b ".new_branch." ".old_branch)
endfunction

function! GitResetHead(...)
  if empty(a:0)
    call inputsave()
    let num_commits = input("# commits reset: ")
    call inputrestore()
  else
    let num_commits = a:0
  endif
  execute("Git reset HEAD~".num_commits)
endfunction

command! -nargs=? Grh call GitResetHead(<f-args>)

autocmd BufEnter * if g:reload_fugitive == v:true | call fugitive#ReloadStatus() | let g:reload_fugitive = v:false | endif
