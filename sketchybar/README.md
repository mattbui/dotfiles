# SketchyBar

This config runs a persistent SbarLua controller for the bottom space and window strip.
Yabai signals arrive through the custom `yabai_event` event. A known `window_focused`
ID changes selection without a query. Structural events schedule an asynchronous yabai
CLI snapshot, and the controller writes the bar only when its normalized drawing key
changes. Normal structural changes update reusable per-space slots in place, so the bar
does not disappear between states.

The controller launches spaces and windows queries concurrently with `sbar.exec`.
SbarLua parses each JSON result directly into a Lua table. Once both callbacks from
one attempt finish, the controller checks the structural revision and normalizes the
combined results. Failed pairs preserve the old scene and retry both queries, up to
three attempts. Non-array space responses retain the labelled-space query fallback.

Normalization refreshes window visibility when the window's space is visible on any
display. An invisible window can replace a previous true observation with false.
Inactive spaces preserve the last observation, so excluded windows do not reappear
when switching away. A later visible observation restores the icon. Hidden, minimized,
sticky, dialog, and destroyed windows remain excluded. Unknown inactive windows are
included provisionally until a visible-space observation classifies them.
There is no extra confirmation query or visibility delay. Concurrent requests are not
an atomic snapshot: revision checks reject superseded pairs, but a space switch whose
event arrives after the callbacks can still produce a mixed snapshot.

Hovering an unselected window icon draws the subtle 10% white capsule.
Left-clicking an icon focuses that exact window through its cached yabai window ID.
Clicks use `~/.config/yabai/scripts/focus-target.sh`, shared with app shortcuts.
It temporarily skips animation for windows on invisible spaces on the focused display.
Cross-display switches keep the normal macOS animation to avoid focus bouncing back.
The helper coordinates with space/display shortcuts and restores skipping to off.
Bar clicks temporarily disable `mouse_follows_focus` until focus settles, then restore
its previous value. Keyboard navigation restores any pending click override first.
Clicks reuse the latest window space and space visibility. During space/display
transitions, unknown visibility falls back to a query.

Requirements:

- SketchyBar
- yabai and jq
- Lua 5.5
- SbarLua installed at `~/.local/share/sketchybar_lua/sketchybar.so`
- `sketchybar-app-font` installed in `~/Library/Fonts`

The vendored app font and icon map come from `kvndrsslr/sketchybar-app-font`. The exact
tag and commit are recorded in `assets/sketchybar-app-font.version`. Update the tracked
copies to the newest upstream version tag with:

```sh
./scripts/update-app-font.sh
```

Pass `--install` to also update the copy in `~/Library/Fonts`. The script copies the
upstream `dist/sketchybar-app-font.ttf`, `dist/icon_map.lua`, and `LICENSE` without
modifying their contents.

Build SbarLua from the cached source with:

```sh
make -C ~/dotfiles/.src/SbarLua install
```

Run the state checks with:

```sh
lua ~/.config/sketchybar/tests/window_state_spec.lua
```
