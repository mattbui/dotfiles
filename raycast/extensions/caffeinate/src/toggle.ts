import { showHUD } from "@raycast/api";
import { labels } from "./model";
import type { Mode } from "./model";
import { perform, refresh } from "./service";

export async function toggle(mode: Mode) {
  try {
    const result = await perform({ kind: "toggle", mode });
    await refresh([...result.changed, mode]);
    const item = result.state.modes[mode];
    await showHUD(
      item.process
        ? `${labels[mode]} sleep prevention on`
        : `${labels[mode]}: ${item.reason || "Off"}`,
    );
  } catch (error) {
    await showHUD(error instanceof Error ? error.message : String(error));
  }
}
