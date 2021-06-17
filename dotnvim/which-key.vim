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

" Create map to add keys to
let g:which_key_map =  {}

" Generals {{{
let g:which_key_map['/'] = 'comment'
let g:which_key_map['-'] = 'split below'
let g:which_key_map['\'] = 'split right'
let g:which_key_map['p'] = 'pick buffer'
let g:which_key_map['o'] = 'insert line below'
let g:which_key_map['O'] = 'insert line above'
let g:which_key_map['D'] = 'delete current file'
let g:which_key_map['R'] = 'rename current file'
let g:which_key_map['N'] = 'create new directory'

let g:which_key_map['e'] = [ ':CocCommand explorer',                         'explorer']
let g:which_key_map['a'] = [ '<Plug>(EasyAlign)',                            'align']
let g:which_key_map['f'] = [ '<Plug>(easymotion-bd-w)',                      'jump word']
let g:which_key_map['l'] = [ '<Plug>(easymotion-lineforward)',               'line forward']
let g:which_key_map['h'] = [ '<Plug>(easymotion-linebackward)',              'line backward']
let g:which_key_map['M'] = [ ':MinimapToggle',                               'toggle minimap']
let g:which_key_map['W'] = [ ':BufferCloseAllButCurrent',                    'close other tabs']
let g:which_key_map['Q'] = [ ':q!',                                          'quit without save']
let g:which_key_map['S'] = [ ':source $MYVIMRC | echo "Saved Vim Settings"', 'save settings']
let g:which_key_map['V'] = [ ':e $MYVIMRC',                                  'vim settings']
" }}}

" Git mappings - g+ {{{
nnoremap <silent> <leader>gco :call GitChangeBranch()<cr>
nnoremap <silent> <leader>gcb :call GitNewBranch()<cr>
let g:which_key_map.g = {
      \ 'name': '+git',
      \ 'co':   'change branch',
      \ 'cb':   'new branch',
      \ 'r':    [':Grefresh',                    'refresh'],
      \ 'R':    [':Grh',                         'reset'],
      \ 'C':    [':Gcommit',                     'commit'],
      \ 'P':    [':call GitPushCurrentBranch()', 'push'],
      \ 'L':    [':call GitPull()',              'pull'],
      \ 'a':    [':Gwrite',                      'add current file'],
      \ 'U':    [':Git reset %',                 'undo current file'],
      \ 'A':    [':Git add .',                   'add all'],
      \ 'D':    [':Git diff',                    'global diff'],
      \ 'B':    [':Git blame',                   'blame'],
      \ 'S':    [':G',                           'status'],
      \ 'l':    [':Gclog',                       'log'],
      \ 'j':    ['<Plug>(coc-git-nextchunk)',    'next chunk'],
      \ 'k':    ['<Plug>(coc-git-prevchunk)',    'previous chunk'],
      \ 'd':    ['<Plug>(coc-git-chunkinfo)',    'chunk diff'],
      \ 'u':    [':CocCommand git.chunkUndo',    'undo chunk'],
      \ 's':    [':CocCommand git.chunkStage',   'stage chunk'],
      \ 'n':    ['<Plug>(coc-git-nextconflict)', 'next conflict'],
      \ 'p':    ['<Plug>(coc-git-prevconflict)', 'prev conflict'],
      \ 'b':    [':CocCommand git.keepBoth',     'keep both'],
      \ '>':    [':CocCommand git.keepIncoming', 'keep incoming'],
      \ '<':    [':CocCommand git.keepCurrent',  'keep current'],
      \ }
" }}}

" Terminal mappings - t+ {{{
let g:which_key_map.t = {
      \ 'name': '+terminal',
      \ 'n':    [':FloatermNew',                  'new terminal'],
      \ '\':    [':FloatermNew --wintype=vsplit --width=90', 'new terminal right'],
      \ '-':    [':FloatermNew --wintype=split --height=25',  'new terminal below'],
      \ 't':    [':FloatermToggle',               'toggle terminal'],
      \ }
" }}}

" Markdown mappings - m+ {{{
let g:which_key_map.m = {
      \ 'name': '+markdown',
      \ 'p':    ['<Plug>MarkdownPreview',     'preview'],
      \ 's':    ['<Plug>MarkdownPreviewStop', 'stop preview'],
      \ 't':    [':GenTocGFM',                'gen table of contents'],
      \ }
" }}}

" Code actions mappings - c+ {{{
" Formatting selected code.
xmap <silent> <leader>cf  <Plug>(coc-format-selected)
nmap <silent> <leader>cf  :call CocAction('format')<CR>
nmap <silent> <leader>cp  <Plug>(pydocstring)

let g:which_key_map.c = {
      \ 'name': '+code-actions',
      \ 'f':    'format',
      \ 'd':    'pydocstring',
      \ 'a':    ['<Plug>(coc-fix-current)',                                       'autofix current file'],
      \ 's':    [":call CocAction('runCommand', 'editor.action.organizeImport')", 'sort imports'],
      \ 'r':    ['<Plug>(coc-rename)',                                            'rename'],
      \ 'o':    [":call CocAction('fold', <f-args>)",                             'fold'],
      \ 'n':    [":cnext",                                                        'quickfix next'],
      \ 'p':    [":cprevious",                                                    'quickfix previous'],
      \ }
" }}}

" Window commands mappings - w+ {{{
nnoremap <leader>ww <C-w>

let g:which_key_map.w = {
      \ 'name': '+windows',
      \ 'w':    'command',
      \ 'o':    [':wincmd o', 'only current'],
      \ 'j':    [':wincmd j', 'move down'],
      \ 'k':    [':wincmd k', 'move up'],
      \ 'h':    [':wincmd h', 'move left'],
      \ 'l':    [':wincmd l', 'move right'],
      \ 'r':    [':wincmd r', 'rotate down/right'],
      \ 'R':    [':wincmd R', 'rotate up/left'],
      \ 'J':    [':wincmd J', 'move bot'],
      \ 'K':    [':wincmd K', 'move top'],
      \ 'H':    [':wincmd H', 'move left'],
      \ 'L':    [':wincmd L', 'move right'],
      \ }
" }}}

" IPython commands mappings - i+ {{{
nnoremap <silent> <leader>ib :IPythonCellInsertBelow<CR>o
nnoremap <silent> <leader>ia :IPythonCellInsertAbove<CR>o

let g:which_key_map.i = {
      \ 'name': '+ipython',
      \ 'a':    'insert cell above',
      \ 'b':    'insert cell below',
      \ 'i':    [':SlimeSend1 ipython',     'ipython'],
      \ 's':    [':call IPynbStart()',      'start'],
      \ 'r':    [':call IPynbAutoReload()', 'autoreload'],
      \ 'm':    [':IPythonCellToMarkdown',  'markdown cell'],
      \ 'n':    [':IPythonCellNextCell',    'next cell'],
      \ 'p':    [':IPythonCellPrevCell',    'previous cell'],
      \ 'j':    [':IPythonCellNextCell',    'next cell'],
      \ 'k':    [':IPythonCellPrevCell',    'previous cell'],
      \ 'R':    [':IPythonCellRestart',     'restart'],
      \ 'd':    [':SlimeSend1 %debug',      'debug'],
      \ 'q':    [':SlimeSend1 exit',        'quit'],
      \ 'c':    [':SlimeSend0 "\x03"',      'cancel'],
      \ }
" }}}

" Ignore {{{
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
" }}}

" Register which key map
call which_key#register('<Space>', "g:which_key_map")

nnoremap <silent> <leader> :<c-u>WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :<c-u>WhichKeyVisual '<Space>'<CR>
