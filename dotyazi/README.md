# Yazi configuration

This config keeps Yazi's native previews, openers, selection, copy/paste,
trash, deletion, creation, and archive extraction. `keymap.toml` only adapts
the preferred keys and macOS/tmux integrations.

Homebrew installs `yazi` and `sevenzip`; the latter supplies `7zz` for Yazi's
native archive preview and extraction.

Launch with `yazi`. Both `<Esc>` and `<C-[>` retain Yazi's native behavior for
clearing selections, leaving visual mode, or cancelling a search.
