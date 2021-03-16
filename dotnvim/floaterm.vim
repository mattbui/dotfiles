let g:floaterm_opener = 'edit'
let g:floaterm_wintype = 'split'
let g:floaterm_width = 70
let g:floaterm_height = 20

autocmd  FileType floaterm set nonumber norelativenumber

" Key mappings for floaterm
nnoremap   <silent>   <M-t>   :FloatermToggle<CR>
tnoremap   <silent>   <M-t>   <C-\><C-n>:FloatermToggle<CR>
tnoremap   <silent>   <M-n>    <C-\><C-n>:FloatermNew<CR>
tnoremap   <silent>   <M-q>    <C-\><C-n>:FloatermKill<CR>
tnoremap   <silent>   <M-j>    <C-\><C-n>:FloatermNext<CR>
tnoremap   <silent>   <M-k>    <C-\><C-n>:FloatermPrev<CR>

" Navigate with ctrl+hjkl (required tmux-vim-nav)
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-h> <C-\><C-n>:TmuxNavigateLeft<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-j> <C-\><C-n>:TmuxNavigateDown<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-k> <C-\><C-n>:TmuxNavigateUp<CR>
autocmd  FileType floaterm tnoremap <buffer> <silent> <C-l> <C-\><C-n>:TmuxNavigateRight<CR>
