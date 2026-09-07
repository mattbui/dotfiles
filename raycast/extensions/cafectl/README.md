# cafectl

Local Raycast shortcuts for the `cafectl` service. The three commands call `cafectl toggle display`, `cafectl toggle system`, and `cafectl toggle disk`. Command IDs remain display-toggle, system-toggle, and disk-toggle.

`cafectl` owns the menu bar, sleep prevention, settings, and power automation. Raycast does not poll, start the service, or save a second copy of its settings. Configure automatic activation and power policies in the cafectl menu.

## Setup

1. Install cafectl and start its service separately, for example with `brew services start cafectl`.
2. Import this directory with Raycast's Import Extension command.
3. Run a cafectl toggle command or assign it a hotkey.

The extension checks `/opt/homebrew/bin/cafectl` and `/usr/local/bin/cafectl`. For a custom installation, set the absolute executable path in Raycast's extension preferences.

Commands display the CLI result or error in a HUD. A timeout or transport failure can leave the result uncertain. Check the cafectl menu before toggling again. The extension never retries a toggle automatically.

## Upgrading from the original extension

Before switching, use the old extension's Turn Off All to release its detached caffeinate processes. The proxy does not stop or adopt those processes, migrate old preferences, or start cafectl. Old Raycast menu bar commands and startup/power preferences are removed.

Quitting Raycast does not affect cafectl. Manage the service independently.

## Development

`npm run build` builds locally. `npm run dev` runs the Raycast development watcher. `npm run lint` checks source and formatting without the Raycast Store author lookup. This extension is local-only.
