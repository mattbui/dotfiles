" Better nav for omnicomplete
inoremap <expr> <C-j> ("\<C-n>")
inoremap <expr> <C-k> ("\<C-p>")

" tab in general mode will move to next buffer
" shift+jk to move to next/prev buffer
nnoremap <silent> <S-j> :bnext<CR>
nnoremap <silent> <S-k> :bprevious<CR>
" ctrl-w will close buffer
nnoremap <silent> <C-w> :bw<CR>

" shift-y to yank absolute path with line/range
nnoremap <silent> Y :YankAbsolutePathLine<CR>
xnoremap <silent> Y :YankAbsolutePathRange<CR>

" keeping it centered
nnoremap n nzzzv
nnoremap N Nzzzv

" undo break points
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u
inoremap : :<c-g>u

" go back to past buffer
nnoremap gb <C-o>
" go forward buffer
nnoremap gt <C-i>

" Jump between code blocks
nmap <silent> gm ]m
nmap <silent> gM [m
nmap <silent> gl ]]
nmap <silent> gL [[

noremap! jj <Esc>

" Better tabbing
vnoremap < <gv
vnoremap > >gv

" ctrl-a, ctrl-e for Home and End
inoremap <C-e> <End>
inoremap <C-a> <Home>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
inoremap <M-b> <S-left>
inoremap <M-f> <S-right>
cnoremap <M-b> <S-left>
cnoremap <M-f> <S-right>

nnoremap <Leader>o o<Esc>
nnoremap <Leader>O O<Esc>

" Better window splitting
nnoremap <silent> <Leader>h :leftabove vsplit<CR>
nnoremap <silent> <Leader>j :rightbelow split<CR>
nnoremap <silent> <Leader>k :leftabove split<CR>
nnoremap <silent> <Leader>l :rightbelow vsplit<CR>

" Resize windows
" nnoremap <silent> <M-j>    :resize -2<CR>
" nnoremap <silent> <M-k>    :resize +2<CR>
" nnoremap <silent> <M-h>    :vertical resize -2<CR>
" nnoremap <silent> <M-l>    :vertical resize +2<CR>
nnoremap <silent> =    :vertical resize +2<CR>
nnoremap <silent> -    :vertical resize -2<CR>
nnoremap <silent> +    :resize +2<CR>
nnoremap <silent> _    :resize -2<CR>

" Alternate way to save
nnoremap <silent> <C-s> :w<CR>
inoremap <silent> <C-s> <ESC>:w<CR>
" Alternate way to quit
nnoremap <silent> <C-q> :q<CR>
inoremap <silent> <C-q> <ESC>:q<CR>
" ctrl-q to close terminal windows
tnoremap   <silent> <C-q> <C-\><C-n>:bw!<CR>

" Clear search highlight by pressing ESC or ctrl+c
nnoremap <silent> <ESC> :noh<CR><ESC>
nnoremap <silent> <C-c> :noh<CR><ESC>
