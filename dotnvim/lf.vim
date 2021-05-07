let g:lf_replace_netrw = 1 " Open lf when vim opens a directory
let g:lf_map_keys = 0
let g:lf_width = 0.6
let g:lf_height = 0.6
let g:lf_command_override = '--wintype=float lf'

nnoremap <silent> <C-o> :LfCurrentFileExistingOrNewTab<CR> 
