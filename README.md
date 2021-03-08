# dotfiles

My dotfiles

<p align="center">
  <img src="screen_shot.png">
</p>

## Intialization on a new machine

### Pre-requirements

- curl
- wget
- zsh
- git

### Magic command

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/mattbui/dotfiles/master/initialize.sh)"
```

## TODO

- [x] init:
  - [x] configs:
    - [x] zsh
    - [x] git
    - [x] nvim
    - [x] tmux
    - [x] fzf
    - [x] lf
  - [ ] setup scripts (support for homebrew, apt, apk, without package manager):
    - [ ] zsh
    - [ ] git
    - [ ] nvim
    - [ ] tmux
    - [ ] fzf
    - [ ] lf
    - [ ] fd
    - [x] conda
- [x] zsh:
  - [x] antigen plugins manager
  - [x] auto-complete
  - [x] syntax highlight
  - [x] vim mode
  - [x] manpage
- [x] nvim:
  - [x] basic settings
  - [x] basic key-maps
  - [x] plugins manager
  - [x] colorscheme
  - [x] coc, code completion
  - [x] file explorer
    - [x] lf
    - [x] coc-explorer
  - [x] git: coc-git
  - [x] startify
  - [x] floatterm
  - [ ] jupyter integration
    - [ ] codi interactive code (alternative scratchpad)
    - [ ] [jupyter-vim](https://github.com/jupyter-vim/jupyter-vim) (send code to jupyter kernal)
    - [ ] [vim-ipynb](https://github.com/anosillus/vim-ipynb) (edit code in ipynb files)
  - [x] fzf integration
- [x] tmux:
  - [x] vim-like navigation
  - [x] vim-like copy-mode
  - [x] tmux-line
- [x] fzf: basic configs
  - [x] use fd as default command
  - [ ] open directory/file (fo)
  - [ ] open file in vim (fe)
  - [x] alias finder with fzf (fa)
- [x] lf: basic configs
  - [x] icons: nerd fonts
  - [x] lfcd: map to ctr+o
  - [x] trash
  - [x] addDir, addFile
  - [x] openWithEditor
