# dotfiles

A macOS-focused setup for my personal machines. The Linux configuration is
mainly there to keep remote servers familiar.

## Main setup

- **Terminal:** Alacritty as the primary terminal, Ghostty as a backup, and tmux
  for a consistent local and remote workflow.
- **Editor and file manager:** Neovim and Yazi, connected through shared
  shortcuts and tmux popups.
- **Shell:** Zsh with small helpers and fuzzy-finding tools.
- **Window management:** yabai and skhd, with JankyBorders for visual feedback.

## Repository layout

- `dotzsh/` — shell configuration, aliases, and helper scripts.
- `dottmux/` — tmux configuration, mappings, popups, and session scripts.
- `dotnvim/` — Neovim configuration and plugin setup.
- `dotyazi/` — Yazi keymaps, theme, plugins, and tmux helpers.
- `dotyabai/` — yabai and skhd configuration.
- `dotpi/` — Pi configuration, extensions, and themes.
- `dotcodex/` — Codex skills and hooks.
- `dotdirenv/`, `dotignore/`, and `dotrevdiff/` — supporting development-tool configuration.
- `others/` — Alacritty, Ghostty, borders, and other application-specific files.
- `init/` — package installation and symlink scripts.

More detail is available in the component READMEs under `dotnvim/`, `dotyazi/`,
and `dotpi/`.

## Setup

The initialization script clones the repository into `~/dotfiles`, links
configurations, updates `.zshrc`, and installs platform-specific dependencies:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/mattbui/dotfiles/main/initialize.sh)"
```

These are personal setup scripts. Review them before running:
`init/link.sh` replaces existing configuration targets with symlinks into this
repository.
