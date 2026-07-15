# Yabai layout setup

This configuration uses display-aware layouts. Displays with an aspect ratio
below `2.0` use yabai's native stack layout. Wide displays use a BSP layout that
can switch between two side-by-side stacks and one centered stack.

## Notation

Windows inside the same brackets share one stack leaf:

```text
[A, B] | [C]
```

`A` and `B` are stacked on the left; `C` occupies the right. In these examples,
the rightmost window in a bracket is visible on top. `*` marks the focused
window:

```text
[A, *B] | [C]
```

Floating, minimized, hidden, and ignored windows are not layout candidates.

## Layouts

### Normal display

All tiled windows use yabai's native stack layout:

```text
[A, B, C]
```

### Wide solo

A single tiled window is centered with symmetric side padding:

```text
[PAD][A][PAD]
```

`[PAD]` represents the symmetric empty space on either side of the centered
leaf.

### Wide two-stack

With two or more windows, the default wide layout is a BSP root with a stack on
each side, starting with an even `0.5` split:

```text
[A, B] | [C, D]
```

There is no persistent main window. The visible right-side member is only an
inferred main, and side membership is reconstructed from the current BSP tree.

### Wide centered-stack

All tiled windows share one centered BSP leaf:

```text
[PAD][A, B, C, D][PAD]
```

This remains a BSP space rather than switching to yabai's native stack layout.
The selected wide mode is stored per space. A wide space with only one tiled
window always appears as wide-solo; its stored mode takes effect when a second
window arrives.

## Focus

- `option-h/l` focuses the left/right leaf. At an edge it continues to the
  previous/next space.
- `option-j/k` cycles through members of the current stack.
- Focusing a window does not permanently assign it as a main window.

Switching from two-stack to centered-stack keeps the focused tiled window on
top:

```text
[A, C, D] | [*B]
          ↓
[PAD][A, C, D, *B][PAD]
```

Switching back puts the focused/visible tiled member on the right and all other
members on the left:

```text
[PAD][A, C, D, *B][PAD]
          ↓
[A, C, D] | [*B]
```

If focus belongs to a floating window during a mode switch, the layout prefers
the visible right member, then the visible left member. Floating focus is not
stolen.

## Window arrivals

New, moved-in, shown, deminimized, and un-floated windows follow these rules:

- In two-stack mode, they join the left stack and become visible.
- In centered-stack mode, they join the only stack and become visible.
- With no other tiled window, they use wide-solo.

Wide spaces configure `window_placement first_child` and
`window_insertion_point first`. This places an arrival at the first root child
before reconciliation, reducing visible movement before it joins the left
stack.

## Moving between side stacks

Use `option-shift-h/l` to move the focused tiled window to the left/right
stack. This command is active only in wide two-stack mode. Moving to the side it
already occupies does nothing.

When the source side has multiple members, the focused window simply joins the
destination and becomes visible:

```text
[A, *B] | [C]
          ↓ move right
[A]     | [C, *B]
```

Moving the final member of a side does not collapse the two-stack layout. A
hidden destination member reseeds the vacated side while the visible
destination member stays in place:

```text
[A] | [B, C]
       C visible
       ↓ move A right
[B] | [C, *A]
```

With exactly one window on each side, moving the final member performs a side
swap:

```text
[*A] | [B]
      ↓ move A right
[B]  | [*A]
```

## Windows leaving a layout

Closing, minimizing, hiding, floating, or moving a tiled window away removes it
from the candidate set. If that removes the final member of one side, the
remaining windows reseed both sides when possible:

```text
[A, B] | [C]
          ↓ C leaves
[A]    | [B]
```

If only one tiled candidate remains, the space becomes wide-solo. Returning or
un-floating a window treats it as a new arrival, so it joins the left stack in
two-stack mode.

## Moving between spaces

Use `command-option-h/l` for the previous/next space, or
`command-option-1..9` for a labeled destination.

The move wrapper prepares the destination's insertion policy before moving the
window:

```text
inspect destination → set insertion policy → move → follow → reconcile
```

This matters when crossing between normal and wide displays. The insertion
settings are global, so applying the destination layout only after the move
would be too late to control its initial placement. The source space is repaired
lazily the next time it becomes active.

## Keybindings

### Window focus and closing

| Shortcut | Action |
| --- | --- |
| `option-h/l` | Focus the left/right leaf; continue to the previous/next space at an edge |
| `option-j/k` | Focus south/north, or cycle forward/backward through the current stack |
| `command-w` | Close normally; repair stale focus in Notes, Messages, Finder, and Calendar |
| `escape` in Antinote | Return focus to the recent yabai window |

### Moving windows

| Shortcut | Action |
| --- | --- |
| `option-shift-h/l` | Move the focused tiled window to the left/right stack |
| `command-option-h/l` | Move the focused window to the previous/next space and follow it |
| `command-option-1..9` | Move the focused window to `space-1..9` and follow it |

### Focusing spaces

Spaces are labeled from left to right across displays, then by Mission Control
index.

| Shortcut | Action |
| --- | --- |
| `option-1..9` | Focus `space-1..9` |
| `control-1..9` | Focus `space-1..9` using the alternate binding |

### Layout, resize, and float

| Shortcut | Action |
| --- | --- |
| `command-option-return` | Toggle two-stack/centered-stack |
| `option-i` | Show current layout, window distribution, and active ratio |
| `option-r` | Repair the current layout while preserving mode and ratios |
| `option-0` | Reset ratios to defaults and repair the current layout |
| `option-minus` | Shrink the focused float, centered layout, or focused two-stack side |
| `option-equal` | Grow the focused float, centered layout, or focused two-stack side |
| `option-shift-minus/equal` | Shrink/grow by four steps |
| `option-return` | Toggle fullscreen float |
| `option-shift-return` | Toggle centered float |

### Application focus

These bindings focus an existing window or open the application when needed.

| Shortcut | Application |
| --- | --- |
| `command-option-control-s` | Slack |
| `command-option-control-t` | Alacritty |
| `command-option-control-shift-t` | Ghostty |
| `command-option-control-c` | ChatGPT |
| `command-option-control-b` | Arc |
| `command-option-control-d` | Discord |
| `command-option-control-f` | Find My |
| `command-option-control-m` | Messages |

### Maintenance and ignore rules

| Shortcut | Action |
| --- | --- |
| `command-option-shift-r` | Restart yabai and report readiness |
| `command-option-r` | Refresh display/space labels |
| `command-option-period` | Toggle the focused application's ignore rule |

The canonical reconciliation entry point is `scripts/apply-layout.sh`.
