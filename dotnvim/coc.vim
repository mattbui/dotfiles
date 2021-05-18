let g:coc_global_extensions = [
      \'coc-marketplace',
      \'coc-pyright',
      \'coc-json',
      \'coc-prettier',
      \'coc-yaml',
      \'coc-highlight',
      \'coc-explorer',
      \'coc-git',
      \'coc-snippets'
      \]

" use <cr> to confirm completion
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

" use tab for trigger completion with characters
" use tab and shift-tab to navigate the completion list
inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Use gk to show documentation in preview window.
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction
nnoremap <silent> gk :call <SID>show_documentation()<CR>
nmap <silent> gj <Plug>(coc-float-hide)
nmap <silent> gh <Plug>(coc-float-hide)

" Use `gn` and `gp` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> gp <Plug>(coc-diagnostic-prev)
nmap <silent> gn <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <down> and <up> for scroll float windows/popups.
nnoremap <silent><nowait><expr> <down> coc#float#has_scroll() ? coc#float#scroll(1) : "\<down>"
nnoremap <silent><nowait><expr> <up> coc#float#has_scroll() ? coc#float#scroll(0) : "\<up>"
inoremap <silent><nowait><expr> <down> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<down>"
inoremap <silent><nowait><expr> <up> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<up>"
vnoremap <silent><nowait><expr> <down> coc#float#has_scroll() ? coc#float#scroll(1) : "\<down>"
vnoremap <silent><nowait><expr> <up> coc#float#has_scroll() ? coc#float#scroll(0) : "\<up>"

" Add `:Format` command to format current buffer.
command! -nargs=0 Format      :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold        :call CocAction('fold', <f-args>)

" Add `:SortImport` command for organize imports of the current buffer.
command! -nargs=0 SortImport  :call CocAction('runCommand', 'editor.action.organizeImport')

command! -nargs=? Marketplace   :CocList marketplace <args>

" " Disable coc during easy motion
autocmd User EasyMotionPromptBegin silent! CocDisable
autocmd User EasyMotionPromptEnd silent! CocEnable
