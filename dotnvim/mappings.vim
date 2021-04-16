" Better nav for omnicomplete
inoremap <expr> <C-j> ("\<C-n>")
inoremap <expr> <C-k> ("\<C-p>")

" tab in general mode will move to next buffer
" nnoremap <TAB> :bnext<CR>
" shift-tab will go back to prev buffer
" nnoremap <S-TAB> :bprevious<CR>
" shift+jk to move to next/prev buffer
nnoremap <silent> <S-j> :bnext<CR>
nnoremap <silent> <S-k> :bprevious<CR>
" alt-w will close buffer
nnoremap <silent> <C-w> :bw<CR>

" go back to past buffer
nnoremap gb <C-o>

noremap! jj <Esc>

" Better tabbing
vnoremap < <gv
vnoremap > >gv

nnoremap <Leader>o o<Esc>
nnoremap <Leader>O O<Esc>

" Better window splitting
nnoremap <silent> <Leader>\ :vsplit<CR>
nnoremap <silent> <Leader>- :split<CR>

" Use alt + hjkl to resize windows
nnoremap <silent> <M-j>    :resize -2<CR>
nnoremap <silent> <M-k>    :resize +2<CR>
nnoremap <silent> <M-h>    :vertical resize -2<CR>
nnoremap <silent> <M-l>    :vertical resize +2<CR>

" Alternate way to save
nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <ESC>:w<CR>
" Alternate way to quit
nnoremap <silent> <C-q> :q<CR>
inoremap <silent> <C-q> <ESC>:q<CR>

" Clear search highlight by pressing ESC or ctrl+c
nnoremap <silent> <ESC> :noh<CR><ESC>
nnoremap <silent> <C-c> :noh<CR><ESC>
