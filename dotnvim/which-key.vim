" Create map to add keys to
let g:which_key_map =  {}
" Define a separator
let g:which_key_sep = '→'
" set timeoutlen=100

let g:which_key_use_floating_win = 0

" Change the colors if you want
highlight default link WhichKey          Operator
highlight default link WhichKeySeperator DiffAdded
highlight default link WhichKeyGroup     Identifier
highlight default link WhichKeyDesc      Function

" Hide status line
autocmd! FileType which_key
autocmd  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 noshowmode ruler

let g:which_key_map['/'] = 'comment'
let g:which_key_map['-'] = 'split below'
let g:which_key_map['\'] = 'split right'
let g:which_key_map['o'] = 'insert line below'
let g:which_key_map['O'] = 'insert line above'

let g:which_key_map['e'] = [ ':CocCommand explorer',            'explorer' ]
let g:which_key_map['a'] = [ '<Plug>(EasyAlign)',               'align' ]
let g:which_key_map['r'] = [ ':Rg',                             'ripgrep' ]
let g:which_key_map['t'] = [ ':FloatermToggle',                 'toggle terminal']
let g:which_key_map['f'] = [ '<Plug>(easymotion-w)',            'jump word forward']
let g:which_key_map['b'] = [ '<Plug>(easymotion-b)',            'jump word backward']
let g:which_key_map['l'] = [ '<Plug>(easymotion-lineforward)',  'line forward']
let g:which_key_map['h'] = [ '<Plug>(easymotion-linebackward)', 'line backward']
let g:which_key_map['j'] = [ '<Plug>(easymotion-j)',            'line downward']
let g:which_key_map['k'] = [ '<Plug>(easymotion-k)',            'line upward']
let g:which_key_map['w'] = [ ':bw',                             'close buffer']
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
