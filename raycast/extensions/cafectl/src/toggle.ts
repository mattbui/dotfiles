import { getPreferenceValues, showHUD } from "@raycast/api";
import { access, constants } from "node:fs/promises";
import { execFile } from "node:child_process";
import { isAbsolute } from "node:path";
import { promisify } from "node:util";
import { labels } from "./model";
import type { Mode } from "./model";

const execute = promisify(execFile);
const statusLabels: Record<string, string> = {
  On: "caffeinated",
  Off: "caffeine off",
  Waiting: "caffeine on hold",
};

async function executable(): Promise<string> {
  const configured = getPreferenceValues<{
    cafectlPath?: string;
  }>().cafectlPath?.trim();
  if (configured && !isAbsolute(configured)) {
    throw new Error("Set an absolute cafectl path in extension preferences");
  }
  for (const path of configured
    ? [configured]
    : ["/opt/homebrew/bin/cafectl", "/usr/local/bin/cafectl"]) {
    try {
      await access(path, constants.X_OK);
      return path;
    } catch {
      // Try the other Homebrew location when no explicit path was supplied.
    }
  }
  throw new Error("cafectl not found. Set its path in extension preferences");
}

export async function toggle(mode: Mode) {
  try {
    const path = await executable();
    // Never retry a toggle: a transport failure may follow a successful change.
    const { stdout } = await execute(path, ["toggle", mode], {
      timeout: 10_000,
      maxBuffer: 1024 * 1024,
      encoding: "utf8",
    });
    const status = stdout.match(
      new RegExp(`^${mode}: (On|Off|Waiting)\\b`, "m"),
    );
    await showHUD(
      status
        ? `${labels[mode]} ${statusLabels[status[1]]}`
        : `${labels[mode]} toggle sent to cafectl`,
    );
  } catch (error) {
    const failure = error as Error & { stderr?: string; killed?: boolean };
    await showHUD(
      failure.killed
        ? "cafectl timed out. Check its menu before toggling again"
        : failure.stderr?.trim() || failure.message || String(error),
    );
  }
}
