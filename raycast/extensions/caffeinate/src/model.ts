export const modes = ["display", "system", "disk"] as const;
export type Mode = (typeof modes)[number];
export const labels: Record<Mode, string> = {
  display: "Display",
  system: "System",
  disk: "Disk",
};
export const flags: Record<Mode, string> = {
  display: "-d",
  system: "-i",
  disk: "-m",
};
export const policies = {
  always: "Allow on battery",
  plugged: "Only while plugged in",
  battery: "Only when battery above 20%",
} as const;
export type Policy = keyof typeof policies;
export type Power = { source: "plugged" | "battery"; percent: number | null };
export type ProcessIdentity = {
  pid: number;
  started: string;
  uid: number;
  command: string;
};
export type Settings = { startup: boolean; policy: Policy };
export type ModeState = Settings & {
  process?: ProcessIdentity;
  handledSession?: string;
  reason?: string;
};
export type State = { version: 1; modes: Record<Mode, ModeState> };

export function initialState(): State {
  return {
    version: 1,
    modes: {
      display: { startup: false, policy: "always" },
      system: { startup: false, policy: "always" },
      disk: { startup: false, policy: "always" },
    },
  };
}

export function blocked(
  policy: Policy,
  power: Power | null,
): string | undefined {
  if (policy === "always") return;
  if (!power) return "Cannot read power status";
  if (power.source === "plugged") return;
  if (policy === "plugged") return "Only allowed while plugged in";
  if (power.percent === null) return "Cannot read battery charge";
  if (power.percent <= 20) return "Battery must be above 20%";
}

export function sameProcess(
  a: ProcessIdentity,
  b: ProcessIdentity | null,
): boolean {
  return (
    !!b &&
    a.pid === b.pid &&
    a.started === b.started &&
    a.uid === b.uid &&
    a.command === b.command
  );
}

export function ownedProcess(
  mode: Mode,
  expected: ProcessIdentity,
  actual: ProcessIdentity | null,
  uid: number,
): boolean {
  return (
    expected.uid === uid &&
    expected.command === `/usr/bin/caffeinate ${flags[mode]}` &&
    sameProcess(expected, actual)
  );
}

export function parsePower(output: string): Power {
  const match = output.match(/Now drawing from '(AC Power|Battery Power)'/);
  if (!match) throw new Error("Unrecognized power source");
  const charge = output.match(/\b(\d{1,3})%;/);
  const percent = charge ? Number(charge[1]) : null;
  if (percent !== null && percent > 100)
    throw new Error("Invalid battery charge");
  return { source: match[1] === "AC Power" ? "plugged" : "battery", percent };
}

// Refuse malformed records rather than replacing state and losing track of live processes.
export function parseState(raw: string): State {
  const state = JSON.parse(raw) as State;
  if (state?.version !== 1 || !state.modes)
    throw new Error("Unsupported Caffeinate state");
  for (const mode of modes) {
    const item = state.modes[mode];
    if (
      !item ||
      typeof item.startup !== "boolean" ||
      !Object.hasOwn(policies, item.policy)
    )
      throw new Error("Invalid mode settings");
    if (
      item.handledSession !== undefined &&
      typeof item.handledSession !== "string"
    )
      throw new Error("Invalid session record");
    const p = item.process;
    if (
      p &&
      (!Number.isInteger(p.pid) ||
        p.pid <= 0 ||
        !Number.isInteger(p.uid) ||
        typeof p.started !== "string" ||
        p.command !== `/usr/bin/caffeinate ${flags[mode]}`)
    )
      throw new Error("Invalid process record");
  }
  return state;
}

export function applyPreferences(
  state: State,
  preferences: Record<string, unknown>,
) {
  for (const mode of modes) {
    state.modes[mode].startup = preferences[mode + "Startup"] === true;
    const policy = preferences[mode + "Policy"];
    state.modes[mode].policy =
      typeof policy === "string" && Object.hasOwn(policies, policy)
        ? (policy as Policy)
        : "always";
  }
}
