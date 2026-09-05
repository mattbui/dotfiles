# SketchyBar

This config runs a persistent SbarLua controller for the bottom space and window strip.
Yabai signals arrive through the custom `yabai_event` event. A known `window_focused`
ID changes selection without a query. Structural events schedule an asynchronous yabai
CLI snapshot, and the controller writes the bar only when its normalized drawing key
changes. Normal structural changes update reusable per-space slots in place, so the bar
does not disappear between states.

Window visibility is learned per window ID. Once observed visible, a window stays
eligible across space transitions even if a later `is-visible` value is false.
The separate spaces and windows queries can straddle a switch, so that value alone
cannot remove a known window. Hidden, minimized, sticky, dialog, and destroyed windows
are still excluded. Unknown inactive windows are included provisionally; their first
visible-space observation can exclude invisible helpers such as Homerow.
An already observed window that an app later orders offscreen without hiding,
minimizing, or destroying it stays listed under this policy.

Hovering an unselected window icon draws the 20% white capsule from the design study.
Left-clicking an icon focuses that exact window through its cached yabai window ID.

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
