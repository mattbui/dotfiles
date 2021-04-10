" Create map to add keys to
let g:which_key_map =  {}
" Define a separator
let g:which_key_sep = '→'
" set timeoutlen=100

let g:which_key_use_floating_win = 0
let g:which_key_hspace = 10

" Change the colors if you want
highlight default link WhichKey          Operator
highlight default link WhichKeySeperator DiffAdded
highlight default link WhichKeyGroup     Identifier
highlight default link WhichKeyDesc      Function

" Hide status line
autocmd! FileType which_key
autocmd  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 noshowmode ruler

let g:which_key_map.s = {
      \ 'name': '+startify',
      \ 'h':    [':Startify',              'home'],
      \ 's':    [':SSave',                 'save session'],
      \ 'i':    [':mksession Session.vim', 'save session here'],
      \ 'l':    [':SLoad',                 'load sessison'],
      \ 'd':    [':SDelete',               'delete sessison'],
      \ 'x':    [':SClose',                'close sessison'],
      \ }

nnoremap <silent> <leader>gco :call GitChangeBranch()<cr>
nnoremap <silent> <leader>gcb :call GitNewBranch()<cr>
let g:which_key_map.g = {
      \ 'name': '+git',
      \ 'co':   'change branch',
      \ 'cb':   'new branch',
      \ 'r':    [':Grefresh',                    'refresh'],
      \ 'C':    [':Gcommit',                     'commit'],
      \ 'P':    [':call GitPushCurrentBranch()', 'push'],
      \ 'L':    [':call GitPull()',              'pull'],
      \ 'a':    [':Gwrite',                      'add current file'],
      \ 'U':    [':Git reset %',                 'undo current file'],
      \ 'A':    [':Git add .',                   'add all'],
      \ 'D':    [':Git diff',                    'global diff'],
      \ 'B':    [':Git blame',                   'blame'],
      \ 'S':    [':Gstatus',                     'status'],
      \ 'l':    [':Glog',                        'log'],
      \ 'j':    ['<Plug>(coc-git-nextchunk)',    'next chunk'],
      \ 'k':    ['<Plug>(coc-git-prevchunk)',    'previous chunk'],
      \ 'd':    ['<Plug>(coc-git-chunkinfo)',    'chunk diff'],
      \ 'u':    [':CocCommand git.chunkUndo',    'undo chunk'],
      \ 's':    [':CocCommand git.chunkStage',   'stage chunk'],
      \ 'n':    ['<Plug>(coc-git-nextconflict)', 'next conflict'],
      \ 'p':    ['<Plug>(coc-git-prevconflict)', 'prev conflict'],
      \ 'kb':   [':CocCommand git.keepBoth',     'keep both'],
      \ 'ki':   [':CocCommand git.keepIncoming', 'keep incoming'],
      \ 'kc':   [':CocCommand git.keepCurrent',  'keep current'],
      \ }

let g:which_key_map.t = {
      \ 'name': '+terminal',
      \ 'n':    [':FloatermNew',                  'new terminal'],
      \ '\':    [':FloatermNew --wintype=vsplit --width=70', 'new terminal right'],
      \ '-':    [':FloatermNew --wintype=split --height=20',  'new terminal below'],
      \ 't':    [':FloatermToggle',               'toggle terminal'],
      \ }

let g:which_key_map.m = {
      \ 'name': '+markdown',
      \ 'p':    ['<Plug>MarkdownPreview',     'preview'],
      \ 's':    ['<Plug>MarkdownPreviewStop', 'stop preview'],
      \ 't':    [':GenTocGFM',                'gen table of contents'],
      \ }

" Formatting selected code.
xmap <leader>fs  <Plug>(coc-format-selected)
nmap <leader>fs  <Plug>(coc-format-selected)

let g:which_key_map.f = {
      \ 'name': '+format',
      \ 'd':    'python docstring',
      \ 'm':    [":call CocAction('format')",                                     'format'],
      \ 'f':    ['<Plug>(coc-fix-current)',                                       'autofix current file'],
      \ 's':    [":call CocAction('runCommand', 'editor.action.organizeImport')", 'sort imports'],
      \ 'r':    ['<Plug>(coc-rename)',                                            'rename'],
      \ 'o':    [":call CocAction('fold', <f-args>)",                             'fold'],
      \ }

let g:which_key_map['/'] = 'comment'
let g:which_key_map['-'] = 'split below'
let g:which_key_map['\'] = 'split right'
let g:which_key_map['o'] = 'insert line below'
let g:which_key_map['O'] = 'insert line above'
let g:which_key_map['D'] = 'delete current file'
let g:which_key_map['R'] = 'rename current file'
let g:which_key_map['N'] = 'create new directory'

let g:which_key_map['e'] = [ ':CocCommand explorer',            'explorer' ]
let g:which_key_map['a'] = [ '<Plug>(EasyAlign)',               'align' ]
let g:which_key_map['l'] = [ '<Plug>(easymotion-w)',            'jump word forward']
let g:which_key_map['h'] = [ '<Plug>(easymotion-b)',            'jump word backward']
let g:which_key_map['W'] = [ ':%bw',                            'close all tab']
let g:which_key_map['Q'] = [ ':q!',                             'quit without save']

" ignore <leader>0-9 for buffer switching
let g:which_key_map.1 = 'which_key_ignore'
let g:which_key_map.2 = 'which_key_ignore'
let g:which_key_map.3 = 'which_key_ignore'
let g:which_key_map.4 = 'which_key_ignore'
let g:which_key_map.5 = 'which_key_ignore'
let g:which_key_map.6 = 'which_key_ignore'
let g:which_key_map.7 = 'which_key_ignore'
let g:which_key_map.8 = 'which_key_ignore'
let g:which_key_map.9 = 'which_key_ignore'
let g:which_key_map.0 = 'which_key_ignore'

" Register which key map
call which_key#register('<Space>', "g:which_key_map")

nnoremap <silent> <leader> :<c-u>WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :<c-u>WhichKeyVisual '<Space>'<CR>
