# AGENTS.md

## Repo Map

- `dotpi/`: Pi app configuration, extensions, themes, and keybindings.
- `dotcodex/`: Codex skills and hooks.
- `dottmux/`: tmux configuration and scripts.
- `dotnvim/`: Neovim configuration.
- `dotzsh/`: zsh configuration.
- `dotyabai/`: yabai and skhd window-management configuration.
- `sketchybar/`: SbarLua space and window bar configuration.
- `dotyazi/`: Yazi file-manager configuration.
- `init/`: setup and install scripts.
- `others/`: app-specific configs, themes, keyboard layouts, and miscellaneous assets.

## Safety

- Do not run install, bootstrap, or link scripts unless explicitly asked, because they may change the local machine state.

## Shell Scripts

### Dialect

- Prefer Bash for new or substantially refactored nontrivial scripts.
- Do not convert unrelated, working POSIX `sh` scripts merely for consistency.
- Use `#!/usr/bin/env bash` for Bash scripts.

### Structure and Naming

- Structure larger executable scripts as functions followed by `main "$@"`.
- Use uppercase `readonly` names for immutable globals.
- Prefix public library functions and shared globals by domain, such as `layout_`.
- Locals and private executable helpers may omit the prefix when their scope is clear.
- Prefer accurate names over abbreviations, but avoid repeating context already established
  by the function.
- Do not use names that imply guarantees the value does not provide.

### Data Flow

- Prefer functions that return values through stdout or status codes.
- Make assignments visible at the call site.
- Avoid functions whose primary effect is silently populating unrelated globals.
- Document shared state consumed or modified by sourced functions.
- Treat persisted state keys, filenames, command arguments, and user-facing output as
  interfaces. Preserve them during internal refactors unless explicitly changing behavior.

### Conventions

- Quote parameter expansions.
- Prefer `[[ ... ]]` and `(( ... ))` in Bash.
- Declare function variables with `local`.
- Use arrays for argument lists where appropriate.
- Pass shell values to `awk` and `jq` through `-v`, `--arg`, or `--argjson` instead of
  interpolating them into program text.
- Do not enable blanket `set -e`; handle expected failures explicitly.
- Use `set -o pipefail` when pipeline failure affects correctness.

### Formatting

- Use 100 characters as the soft line-length limit, including embedded `jq`, `awk`, and
  AppleScript.
- Break long filters and commands by logical operation.
- Comments should explain behavioral intent or non-obvious constraints, not restate
  commands.

### dotyabai Validation

Run from `dotyabai/` after changing its Bash sources:

```sh
for file in yabairc scripts/*.sh; do bash -n "$file"; done
shellcheck yabairc scripts/*.sh
```

## dotpi Sync

When committing or pushing changes for `dotpi`, also commit and push the corresponding dotfiles repo changes.

Translate `dotpi` commit messages by prefixing the scope with `pi/`.

Examples:

- `feat(extension): add new extension` -> `feat(pi/extension): add new extension`
- `fix(auto-review): handle sandbox denial` -> `fix(pi/auto-review): handle sandbox denial`
- `docs: update README` -> `docs(pi): update README`

Before creating a dotfiles commit, check whether the latest relevant `dotpi` commit has already been represented in dotfiles.
