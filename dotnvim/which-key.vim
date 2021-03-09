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

" TODO: ERROR - :Git commit crash with gpgsign
" potential solution:
" - custom commit function to get input from user about commit message
" - open git commit -m <user_input_message> with floaterm
" reference: https://vim.fandom.com/wiki/User_input_from_a_script
" example: https://gist.github.com/itaine/3962039
nnoremap <leader>gc :FloatermNew! git commit -m 

let g:which_key_map.g = {
      \ 'name': '+git',
      \ 'c':    'commit',
      \ 'a':    [':Gwrite',                      'add current file'],
      \ 'R':    [':Git reset %',                 'reset current file'],
      \ 'A':    [':Git add .',                   'add all'],
      \ 'D':    [':Git diff',                    'global diff'],
      \ 'b':    [':Git blame',                   'blame'],
      \ 'r':    [':CocCommand git.refresh',      'refresh'],
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
      \ '\':    [':FloatermNew --wintype=vsplit', 'new terminal right'],
      \ '-':    [':FloatermNew --wintype=split',  'new terminal below'],
      \ 't':    [':FloatermToggle',               'toggle terminal'],
      \ }

let g:which_key_map.m = {
      \ 'name': '+markdown',
      \ 'p':    ['<Plug>MarkdownPreview',     'preview'],
      \ 's':    ['<Plug>MarkdownPreviewStop', 'stop preview'],
      \ }

let g:which_key_map['/'] = 'comment'
let g:which_key_map['-'] = 'split below'
let g:which_key_map['\'] = 'split right'
let g:which_key_map['o'] = 'insert line below'
let g:which_key_map['O'] = 'insert line above'

let g:which_key_map['e'] = [ ':CocCommand explorer',            'explorer' ]
let g:which_key_map['a'] = [ '<Plug>(EasyAlign)',               'align' ]
let g:which_key_map['r'] = [ ':Rg',                             'ripgrep' ]
let g:which_key_map['l'] = [ '<Plug>(easymotion-lineforward)',  'line forward']
let g:which_key_map['h'] = [ '<Plug>(easymotion-linebackward)', 'line backward']
let g:which_key_map['j'] = [ '<Plug>(easymotion-j)',            'line downward']
let g:which_key_map['k'] = [ '<Plug>(easymotion-k)',            'line upward']
let g:which_key_map['w'] = [ ':bd!',                            'close tab']
let g:which_key_map['W'] = [ ':%bd!',                           'close all tab']
let g:which_key_map['q'] = [ '<C-w>q',                          'quit']
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
