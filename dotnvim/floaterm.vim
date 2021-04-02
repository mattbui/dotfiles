let g:floaterm_opener = 'edit'
let g:floaterm_wintype = 'split'
let g:floaterm_width = 70
let g:floaterm_height = 20

autocmd  FileType floaterm set nonumber norelativenumber

" Key mappings for floaterm
nnoremap   <silent>   <C-t>   :FloatermToggle<CR>
tnoremap   <silent>   <C-t>   <C-\><C-n>:FloatermToggle<CR>
tnoremap   <silent>   <C-q>   <C-\><C-n>:FloatermKill<CR>

" Navigate with ctrl+hjkl (required tmux-vim-nav)
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-h> <C-\><C-n>:TmuxNavigateLeft<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-j> <C-\><C-n>:TmuxNavigateDown<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-k> <C-\><C-n>:TmuxNavigateUp<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-l> <C-\><C-n>:TmuxNavigateRight<CR>
