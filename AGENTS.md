# AGENTS.md

## Repo Map

- `dotpi/`: Pi app configuration, extensions, themes, and keybindings.
- `dotcodex/`: Codex skills and hooks.
- `dottmux/`: tmux configuration and scripts.
- `dotnvim/`: Neovim configuration.
- `dotzsh/`: zsh configuration.
- `dotyabai/`: yabai and skhd window-management configuration.
- `dotlf/`: lf file-manager configuration.
- `init/`: setup and install scripts.
- `others/`: app-specific configs, themes, keyboard layouts, and miscellaneous assets.

## Safety

- Do not run install, bootstrap, or link scripts unless explicitly asked, because they may change the local machine state.

## Reference Source

- `.src/` contains cached dependency and package repositories for source-code reference.
- When planning or implementing against third-party behavior, prefer reading `.src/` source code over guessing from memory.
- Treat `.src/` as read-only reference material unless explicitly asked to update it.
- If needed source is missing, ask before cloning/downloading it into `.src/` unless the user has already requested dependency/source inspection.

## dotpi Sync

When committing or pushing changes for `dotpi`, also commit and push the corresponding dotfiles repo changes.

Translate `dotpi` commit messages by prefixing the scope with `pi/`.

Examples:

- `feat(extension): add new extension` -> `feat(pi/extension): add new extension`
- `fix(auto-review): handle sandbox denial` -> `fix(pi/auto-review): handle sandbox denial`
- `docs: update README` -> `docs(pi): update README`

Before creating a dotfiles commit, check whether the latest relevant `dotpi` commit has already been represented in dotfiles.
