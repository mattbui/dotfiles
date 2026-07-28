# Yabai layout setup

This configuration provides two display-aware layouts:

- `single-stack` puts every eligible tiled window in one native yabai stack.
- `two-stack` uses left/right stacks on landscape displays and top/bottom
  stacks on portrait displays.

The display shape chooses the two-stack orientation. The display's logical
workspace area chooses the initial layout and spacing profile.

## Display policy

Classification uses the scaled macOS logical workspace before padding:
`width × height`.

| Area class | Logical area | Top | Other edges | Gap | New-space default |
| --- | ---: | ---: | ---: | ---: | --- |
| Compact | `< 3,500,000` | `6` | `8` | `8` | `single-stack` |
| Roomy | `>= 3,500,000` | `6` | `12` | `10` | `two-stack` |

Landscape means `W >= H`; portrait means `H > W`. Rotating a display preserves
its area class while changing the orientation of a selected two-stack layout.

## Layouts

Windows in the same brackets share one stack leaf. The rightmost entry is the
visible member in these examples.

Native single stack:

```text
[A, B, C]
```

Landscape two-stack:

```text
[A, B] | [C, D]
  left     right
```

Portrait two-stack:

```text
top:    [A, B]
        ------
bottom: [C, D]
```

A selected `two-stack` needs at least two eligible windows. With one, the
selection remains stored but the BSP space temporarily presents the window
using the current single-stack sizing:

```text
[padding] [A] [padding]
```

Floating, minimized, hidden, and ignored windows are not candidates. The
ignore list is authoritative: an ignored application remains excluded even if
yabai currently reports one of its windows as tiled.

## Single-stack sizing

Single-stack sizing follows this order:

1. Portrait displays target `80%` of logical height.
2. Ultrawide landscape displays with `W / H >= 2.0` target `65%` of logical
   width.
3. Other landscape displays use ordinary compact or roomy padding.

Centered padding cannot shrink below the active base profile. Horizontal
centering keeps both sides at least `8` compact or `12` roomy. Portrait
centering keeps at least `6` above and `8` compact or `12` roomy below.

## Selection and persisted state

`Alt-S` and `Alt-T` directly select single-stack and two-stack. They are not a
toggle, and selecting the current layout is a silent no-op.

Preferences belong to positional labels such as `space-2`, not yabai space IDs
or UUIDs. A compact/roomy crossing applies the new area-class default.
Geometry changes within the same class preserve a manual selection, while a
selected two-stack always follows the current landscape or portrait shape.

Four ratios persist independently:

| Ratio | Default | Range |
| --- | ---: | --- |
| Ultrawide single-stack width | `0.65` | `0.30` to the base-padding maximum |
| Portrait single-stack height | `0.90` | `0.30` to the base-padding maximum |
| Landscape left/right split | `0.50` | `0.10–0.90` |
| Portrait top/bottom split | `0.50` | `0.10–0.90` |

Changing orientation does not overwrite the other orientation's ratio.

## Arrivals and removals

Arrivals include newly created, moved-in, deminimized, un-floated, newly
unignored, and application-visible windows.

Native single-stack handles arrivals directly. In two-stack, the global
`first` insertion point and `first_child` placement produce the desired
two-window bootstrap:

```text
landscape: [B] | [A]

portrait:  [B]
           ---
           [A]
```

The existing solo window `A` becomes the stable second stack (right or bottom);
the arrival `B` becomes the first stack (left or top). Later arrivals join the
first stack and become visible without disturbing the second stack.

Closing, hiding, minimizing, floating, ignoring, or moving away a window
removes it from the candidate set. If a stack empties while at least two
candidates remain, reconciliation reseeds it from the surviving stack. With
one candidate, the selected two-stack returns to its temporary single-window
presentation.

Moving a window to another space follows and reconciles the destination
immediately. The inactive source is repaired lazily when it next becomes
active.

## Focus and movement

- `Alt-H/L` focuses west/east. At an edge it focuses the previous/next space
  and wraps.
- `Alt-J/K` first focuses south/north, then cycles forward/backward through the
  current stack and wraps.
- In a horizontal two-stack, `Alt-Shift-H/L` moves to the left/right stack.
- In a vertical two-stack, `Alt-Shift-J/K` moves to the bottom/top stack.

Moving toward the current stack, or using a direction that does not apply to
the current arrangement, is a no-op. Moving the final source member preserves
two populated stacks: one member on each side swaps, while a multi-member
destination supplies a replacement to reseed the vacated stack. The explicitly
moved window remains focused.

## Resize, repair, and reset

Tiled resizing changes the applicable saved ratio by `0.025`, or `0.10` with
Shift. Resizing a focused two-stack region changes that region's share.
Temporary single-window presentation changes the applicable single-stack ratio
rather than the saved split. Ordinary landscape single-stack has no ratio, so
tiled resize is a no-op.

Floating windows resize by `80px`, or `320px` with Shift. Raw mouse or yabai
tree resizing is not persisted; `Alt-R` reapplies the saved ratio. `Alt-0`
resets all four ratios to their defaults and repairs without otherwise changing
the selected layout.

## Keybindings

### Focus and close

| Shortcut | Action |
| --- | --- |
| `Alt-H/L` | Focus west/east; otherwise previous/next space with wrap |
| `Alt-J/K` | Focus south/north; otherwise next/previous stack member with wrap |
| `Cmd-W` | Close normally; repair stale focus in Notes, Messages, Finder, and Calendar |
| `Escape` in Antinote | Focus the recent yabai window |

### Layout, resize, and float

| Shortcut | Action |
| --- | --- |
| `Alt-S` | Select single-stack |
| `Alt-T` | Select two-stack using the current display shape |
| `Alt-R` | Repair/reapply while preserving saved ratios |
| `Alt-0` | Reset all four ratios and repair |
| `Alt-I` | Inspect layout, distribution, ratio, padding, and compliance |
| `Alt--` / `Alt-=` | Shrink/grow the focused float or tiled arrangement |
| `Alt-Shift--` / `Alt-Shift-=` | Shrink/grow with the accelerated step |
| `Alt-C` | Toggle a centered float |
| `Alt-Return` | Toggle a fullscreen float within the ordinary tiling area |

### Move windows

| Shortcut | Action |
| --- | --- |
| `Alt-Shift-H/J/K/L` | Move to left/bottom/top/right stack when applicable |
| `Cmd-Alt-H/L` | Move to previous/next space and follow |
| `Cmd-Alt-1..4` | Move to `display-1..4` and follow |
| `Ctrl-Cmd-1..9` | Move to `space-1..9` and follow |

### Focus displays and spaces

Displays are labeled by physical left-to-right order. Spaces are labeled
across displays from left to right, then by Mission Control order.

| Shortcut | Action |
| --- | --- |
| `Alt-1..4` | Focus `display-1..4` |
| `Ctrl-1..9` | Focus `space-1..9` |

### Focus or open applications

| Shortcut | Application |
| --- | --- |
| `Cmd-Alt-Ctrl-S` | Slack |
| `Cmd-Alt-Ctrl-T` | Alacritty |
| `Cmd-Alt-Ctrl-Shift-T` | Ghostty |
| `Cmd-Alt-Ctrl-C` | ChatGPT |
| `Cmd-Alt-Ctrl-B` | Arc |
| `Cmd-Alt-Ctrl-D` | Discord |
| `Cmd-Alt-Ctrl-F` | Find My |
| `Cmd-Alt-Ctrl-M` | Messages |

### Maintenance and ignore rules

| Shortcut | Action |
| --- | --- |
| `Alt-Shift-R` | Restart yabai and report readiness |
| `Alt-D` | Refresh display and space labels |
| `Alt-.` | Toggle the focused application's ignore rule |

## Operational notes

- `scripts/apply-layout.sh` is the canonical reconciliation entry point.
- `yabairc` owns the global arrival defaults:
  `window_insertion_point first` and `window_placement first_child`.
- Signals reconcile the active space on window, application visibility, space,
  and display changes. Overlapping runs share a lock and pending rerun.
- Per-label layout state defaults to
  `~/.local/state/yabai/layout-space-N.json`.
