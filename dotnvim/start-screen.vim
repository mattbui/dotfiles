let g:startify_session_dir = '~/.config/nvim/session'

let g:startify_lists = [
          \ { 'type': 'files',     'header': ['   Files']            },
          \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
          \ { 'type': 'sessions',  'header': ['   Sessions']       },
          \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
          \ ]

" store bookmarks in startify_bookmarks.vim for machine specific bookmarks
" let g:startify_bookmarks = [
"             \ { 'z': '~/.zshrc' },
"             \ '~/Pics',
"             \ ]
if !empty(glob('~/.config/nvim/startify_bookmarks.vim'))
        source ~/.config/nvim/startify_bookmarks.vim
endif

let g:startify_session_delete_buffers = 1
let g:startify_change_to_vcs_root = 1
let g:startify_enable_special = 0

let g:startify_custom_header = [
        \' __  __     __        __    __     ______     ______   ______ ', 
        \'/\ \_\ \   /\ \      /\ "-./  \   /\  __ \   /\__  _\ /\__  _\', 
        \'\ \  __ \  \ \ \     \ \ \-./\ \  \ \  __ \  \/_/\ \/ \/_/\ \/', 
        \' \ \_\ \_\  \ \_\     \ \_\ \ \_\  \ \_\ \_\    \ \_\    \ \_\', 
        \'  \/_/\/_/   \/_/      \/_/  \/_/   \/_/\/_/     \/_/     \/_/'] 

