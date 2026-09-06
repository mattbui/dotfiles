import {
  environment,
  getPreferenceValues,
  launchCommand,
  LaunchType,
} from "@raycast/api";
import { withStore } from "./store";
import { processHost, power, raycastSession } from "./processes";
import { reconcile } from "./engine";
import type { Request } from "./engine";
import { applyPreferences } from "./model";
import type { Mode } from "./model";

export async function refresh(targets: Mode[]) {
  const results = await Promise.allSettled(
    [...new Set(targets)].map((mode) =>
      launchCommand({ name: `${mode}-status`, type: LaunchType.Background }),
    ),
  );
  const failures = results.filter((r) => r.status === "rejected");
  if (failures.length)
    throw new Error(
      "Sleep state saved, but menu refresh failed. Enable the status commands in Raycast.",
    );
}

export async function perform(request: Request) {
  return withStore(environment.supportPath, async (state, save) => {
    const preferences = getPreferenceValues<Record<string, string | boolean>>();
    applyPreferences(state, preferences);
    const [supply, session] = await Promise.all([power(), raycastSession()]);
    if (
      !session &&
      request.kind === "poll" &&
      Object.values(state.modes).some((item) => item.startup)
    ) {
      throw new Error(
        "Cannot identify the Raycast app session for startup automation",
      );
    }
    return reconcile(state, processHost, supply, session, request, save);
  });
}
