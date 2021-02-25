" Better nav for omnicomplete
inoremap <expr> <C-j> ("\<C-n>")
inoremap <expr> <C-k> ("\<C-p>")

" tab in general mode will move to next buffer
nnoremap <TAB> :bnext<CR>
" shift-tab will go back to prev buffer
nnoremap <S-TAB> :bprevious<CR>
" ctrl-w will close buffer
nnoremap <C-w> :bw<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

nnoremap <Leader>o o<Esc>^D
nnoremap <Leader>O O<Esc>^D

" Use alt + hjkl to resize windows
nnoremap <M-j>    :resize -2<CR>
nnoremap <M-k>    :resize +2<CR>
nnoremap <M-h>    :vertical resize -2<CR>
nnoremap <M-l>    :vertical resize +2<CR>

" Alternate way to save
nnoremap <C-s> :w<CR>
" Alternate way to quit
nnoremap <C-q> :wq!<CR>
nnoremap <M-q> :q!<CR>
" <TAB>: completion.
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
" Clear search highlight by pressing ESC
nnoremap <ESC> :noh<CR><ESC>
