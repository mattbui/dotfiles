" Easymotion colors {{{
hi EasyMotionTarget guifg=#E5E9F0 ctermfg=255 guibg=#8FBCBB ctermbg=109 gui=bold cterm=bold
hi EasyMotionTarget2First guifg=#5E81AC ctermfg=67 guibg=NONE ctermbg=NONE gui=bold cterm=bold
hi EasyMotionTarget2Second guifg=#8FBCBB ctermfg=109 guibg=NONE ctermbg=NONE gui=bold cterm=bold
hi EasyMotionShade guifg=#616E88 ctermfg=8 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
" }}}

" Which-key colors {{{
hi WhichKeySeperator guifg=#8fbcbb ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
" }}}

" Minimap colors {{{
hi MinimapCurrentLine ctermbg=238 ctermfg=110 guibg=#3b4252 guifg=#88C0D0
" }}}

" Indent guide colors {{{
hi IndentGuidesOdd guibg=#434C5E
hi IndentGuidesEven guibg=#4C566A
" }}}

" Tabbar colors {{{
hi BufferCurrentSign ctermfg=110 guifg=#88C0D0
hi BufferCurrentTarget cterm=bold ctermfg=110 gui=bold guifg=#88C0D0
hi BufferInactiveTarget cterm=bold ctermbg=238 ctermfg=110 gui=bold guibg=#3b4252 guifg=#88C0D0
hi BufferVisibleTarget cterm=bold ctermbg=240 ctermfg=110 gui=bold guibg=#4c566a guifg=#88C0D0 
" }}}

" Git colors {{{
hi SignColumn guifg=#3b4252 ctermfg=238 guibg=#2e3440 ctermbg=237 gui=NONE cterm=NONE
hi DiffAdd guifg=#a3be8c ctermfg=144 guibg=NONE ctermbg=238 gui=NONE cterm=NONE
hi DiffChange guifg=#ebcb8b ctermfg=222 guibg=NONE ctermbg=238 gui=NONE cterm=NONE
hi DiffDelete guifg=#bf616a ctermfg=131 guibg=NONE ctermbg=238 gui=NONE cterm=NONE
hi DiffText guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=238 gui=NONE cterm=NONE
hi diffAdded guifg=#a3be8c ctermfg=144 guibg=#3b4252 ctermbg=238 gui=NONE cterm=NONE
hi diffChanged guifg=#ebcb8b ctermfg=222 guibg=#3b4252 ctermbg=238 gui=NONE cterm=NONE
hi diffRemoved guifg=#bf616a ctermfg=131 guibg=#3b4252 ctermbg=238 gui=NONE cterm=NONE
hi diffFileId guifg=#5e81ac ctermfg=67 guibg=NONE ctermbg=NONE gui=bold,reverse cterm=bold,reverse
hi diffFile guifg=#3b4048 ctermfg=238 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi diffNewFile guifg=#a3be8c ctermfg=144 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi diffOldFile guifg=#bf616a ctermfg=131 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi gitconfigVariable guifg=#8fbcbb ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
" }}}

" Fugitive colors {{{
hi link fugitiveUntrackedModifier DiffDelete
hi link fugitiveUnstagedModifier DiffChange
hi link fugitiveStagedModifier DiffAdd
hi fugitiveHash guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
" }}}

" Coc-explorer colors {{{
hi CocExplorerIndentLine guifg=#5c6370 ctermfg=241 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerBufferRoot guifg=#8fbcbb ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerFileRoot guifg=#8fbcbb ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerBufferFullPath guifg=#5c6370 ctermfg=241 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerFileFullPath guifg=#5c6370 ctermfg=241 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerBufferReadonly guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerBufferModified guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerBufferNameVisible guifg=#d08770 ctermfg=173 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerFileReadonly guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerFileModified guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerFileHidden guifg=#5c6370 ctermfg=241 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi CocExplorerHelpLine guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
" }}}

" Treesitter colors {{{
hi TSError guifg=#bf616a ctermfg=131 guibg=NONE ctermbg=NONE gui=underline cterm=underline
hi TSPunctDelimiter guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSPunctBracket guifg=#eceff4 ctermfg=255 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSPunctSpecial guifg=#eceff4 ctermfg=255 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSConstant guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSConstBuiltin guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSConstMacro guifg=#8fbcbb ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSStringRegex guifg=#a3be8c ctermfg=144 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSString guifg=#a3be8c ctermfg=144 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSStringEscape guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSCharacter guifg=#a3be8c ctermfg=144 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSNumber guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSBoolean guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSFloat guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSAnnotation guifg=#d08770 ctermfg=173 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSAttribute guifg=#8fbcbb ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSNamespace guifg=#eceff4 ctermfg=255 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSFuncBuiltin guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSFunction guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSFuncMacro guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSParameter guifg=#e5e9f0 ctermfg=255 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSParameterReference guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSMethod guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSField guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSProperty guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSConstructor guifg=#8fbcbb ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSConditional guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSRepeat guifg=#b48ead ctermfg=139 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSLabel guifg=#88c0d0 ctermfg=110 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSKeyword guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSKeywordFunction guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSKeywordOperator guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSOperator guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSException guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSType guifg=#8fbcbb ctermfg=109 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSTypeBuiltin guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSStructure guifg=#B48EAD ctermfg=201 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSInclude guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSVariable guifg=#e5e9f0 ctermfg=255 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSVariableBuiltin guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSText guifg=NONE ctermfg=NONE guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSStrong guifg=NONE ctermfg=NONE guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSEmphasis guifg=NONE ctermfg=NONE guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSUnderline guifg=NONE ctermfg=NONE guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSTitle guifg=None ctermfg=NONE guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSLiteral guifg=NONE ctermfg=None guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSURI guifg=NONE ctermfg=NONE guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
hi TSTag guifg=#81a1c1 ctermfg=109 guibg=NONE ctermbg=NONE gui=italic cterm=italic
hi TSTagDelimiter guifg=#5c6370 ctermfg=241 guibg=NONE ctermbg=NONE gui=NONE cterm=NONE
" }}}
