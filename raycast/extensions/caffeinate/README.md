# Caffeinate

A local-only Raycast extension with independent display, system, and disk sleep prevention. Each active mode has a filled hardware icon. Turning a mode off removes its icon.

## Use locally

1. Open Raycast's **Import Extension** command and choose `/Users/minhbui/dotfiles/raycast/extensions/caffeinate`.
2. Open **Raycast Settings → Extensions → Caffeinate**. Set Start with Raycast and Keep display/system/disk awake separately for each mode.
3. Keep the three **Caffeinate … Status** commands enabled with background refresh. Run each once if it has not been activated. An inactive mode deliberately shows no icon.
4. Run **Caffeinate Display Toggle**, **Caffeinate System Toggle**, or **Caffeinate Disk Toggle**. You can assign each a hotkey or alias.

Each active icon opens a menu with Turn Off, Turn Off All, the current power policy, and Settings. Settings opens the native extension preferences, also accessible when all icons are hidden.

The source has no publishing command. `npm run build` creates a local `dist/` directory. `npm run dev` runs Raycast's development watcher. Dependencies are already installed for this checkout.

## Power policy

| Choice | Behavior |
| --- | --- |
| Allow on battery | Allow prevention at any battery charge. |
| Only while plugged in | Stop on battery and block activation until plugged in. |
| Only when battery above 20% | Stop at 20% or below while on battery. Plugged-in use is always allowed. |

Each mode has its own policy. Start with Raycast is off by default, and the default policy is Allow on battery. Policies also apply to manual activation.

Automation runs during background refresh, nominally every 30 seconds. Raycast can delay the refresh. A brief unplug and replug between checks can be missed. Manual changes refresh icons immediately.

## Startup and quitting

Start with Raycast attempts to activate a mode once per Raycast app session, on its first poll. The power policy takes priority. A blocked startup, manual off, or automatic stop does not repeatedly retry. Replugging or charging above 20% does not restart a mode.

Quitting Raycast removes the icons and pauses automation. Existing caffeinate processes keep running. After Raycast returns, commands verify recorded PIDs, process start times, user IDs, and exact command lines before restoring icons or stopping processes.

Reboot clears running processes. Startup-enabled modes can start again with Raycast. Deactivating a status command is not a Turn Off action. Use Turn Off All before removing the extension.

## Implementation

Six command entries provide three immediate toggles and three menu bar status commands. Native extension preferences are the source of startup and power settings. The state file retains process records and session markers.

Display uses `caffeinate -d`, System uses `-i`, and Disk uses `-m`. Detached processes have no timeout. A shared lock serializes changes, and state files are replaced atomically in Raycast's extension support directory.

System prevention concerns idle sleep. It does not promise to override lid closure, explicit Sleep, or critical battery handling. Disk behavior depends on the drive and enclosure.

## Validation

`npm run lint` checks source and formatting directly. Raycast's Store author lookup is intentionally excluded for this local-only extension. Build checks TypeScript.

Physical unplug and an actual Raycast restart still need a live check.

Menu bar icons use filled SVG assets without bolts, tinted with Raycast's PrimaryText color. Tight view boxes remove unused padding. The artwork uses paths and rectangles without transforms for compatibility with Raycast's renderer. The brown cup-and-saucer PNG is only the extension icon.
