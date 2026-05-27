# Custom Editor Extension

Custom Pi editor implementation

## What it changes

- Replaces Pi's default input editor with `CustomizedEditor`.
- Removes the default editor top/bottom border and draws a compact left prompt marker.
- Uses a beam-style hardware cursor and keeps the cursor positioned correctly while autocomplete/dropdowns are visible.
- Handles focus-in/focus-out terminal events so the cursor is hidden when the terminal loses focus.
- Changes Enter behavior:
  - Enter accepts an active autocomplete item.
  - Enter submits known slash commands.
  - Enter inserts a newline for normal text.
  - Alt+Enter submits the prompt.
- Prevents Tab from triggering autocomplete when the cursor token is empty.

## Inline `@` file/directory picker

Typing `@` at the start of a token opens a custom inline picker below the editor.

Examples:

```text
@
read @src
```

Does not trigger in the middle of a word:

```text
email@domain.com
```

Behavior:

- Uses `fzf` for fuzzy matching.
- Searches files and directories.
- Respects `.gitignore` by default when using `fd`.
- Inserts selected paths without the leading `@`.
- Inserts directories with a trailing `/`.
- Highlights fuzzy matched characters.
- Esc closes the picker while leaving the typed `@query` intact.

The candidate command is read from `PI_INLINE_FZF_COMMAND`, with a built-in `fd`/`find` fallback.

## Inline `@@` line fzf picker

Typing `@@` at the start of a token opens a custom line picker below the editor.

Examples:

```text
@@TODO
explain @@function name
```

Behavior:

- Uses `rg` once to load project line results, then fuzzy-filters them as you type.
- Bare `@@` shows results immediately.
- Spaces are allowed inside the fuzzy query after the first character.
- `@@ ` closes/does not trigger the picker.
- Highlights fzf-matched characters.
- Enter inserts `path/to/file:line`.
- Esc closes the picker while leaving the typed `@@query` intact.
- Shows a widget error if `rg` is not installed.

The ripgrep source command is read from `PI_FZF_RG_COMMAND`, with a built-in `rg` default. Custom commands are not passed the query and should emit `file:line:column:text` lines.

## Files

- `index.ts` — main editor extension and key handling.
- `cursor.ts` — hardware cursor/focus helpers.
- `inline-file-fzf.ts` — single-`@` file and directory picker.
- `inline-lines-fzf.ts` — double-`@@` line fzf picker.
- `package.json` — local dependency on `fzf`.
