# dotfiles

A macOS-focused setup for my personal machines with some Linux configs for remote machines.

## Main setup

- **Terminal:** Alacritty as the primary terminal, Ghostty as a backup, and tmux
  for a consistent local and remote workflow.
- **Editor:** Neovim
- **File manager:** Yazi
- **Shell:** zsh with starship prompt and fzf.
- **Window management:** yabai with skhd, SketchyBar, and JankyBorders

## Repository layout

- `dotzsh/` — shell configuration, aliases, and helper scripts.
- `dottmux/` — tmux configuration, mappings, popups, and session scripts.
- `dotnvim/` — Neovim configuration and plugin setup.
- `dotyazi/` — Yazi keymaps, theme, plugins, and tmux helpers.
- `dotyabai/` — yabai and skhd configuration.
- `sketchybar/` — SbarLua space and window bar configuration.
- `dotpi/` — Pi configuration, extensions, and themes.
- `dotcodex/` — Codex skills and hooks.
- `dotignore/` and `dotrevdiff/` — supporting development-tool configuration.
- `others/` — Alacritty, Ghostty, sesh, starship prompt and other application-specific files.
- `init/` — package installation and symlink scripts.

More detail is available in the component READMEs under `dotnvim/`, `dotyazi/`,
`dotyabai/`, and `dotpi/`.

## Setup

The initialization script clones the repository into `~/dotfiles`, links
configurations, updates `.zshrc`, and installs platform-specific dependencies:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/mattbui/dotfiles/main/initialize.sh)"
```

These are personal setup scripts. Review them before running:
`init/link.sh` replaces existing configuration targets with symlinks into this
repository.
