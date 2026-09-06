import { blocked, modes } from "./model";
import type { Mode, Power, ProcessIdentity, State } from "./model";

export interface Host {
  alive(mode: Mode, identity: ProcessIdentity): Promise<boolean>;
  start(mode: Mode): Promise<ProcessIdentity>;
  stop(mode: Mode, identity: ProcessIdentity): Promise<void>;
}
export type Request =
  | { kind: "poll" }
  | { kind: "toggle"; mode: Mode }
  | { kind: "off"; mode: Mode }
  | { kind: "off-all" };

// The caller holds the cross-command lock and persists after every process transition.
export async function reconcile(
  state: State,
  host: Host,
  power: Power | null,
  session: string | null,
  request: Request,
  save: () => Promise<void>,
) {
  const changed = new Set<Mode>();
  for (const mode of modes) {
    const item = state.modes[mode];
    if (item.process && !(await host.alive(mode, item.process))) {
      delete item.process;
      item.reason = "Previous process ended";
      changed.add(mode);
      await save();
    }
  }
  // Capture intent before enforcing policy: toggling an active mode always means off.
  const toggleOff =
    request.kind === "toggle" && !!state.modes[request.mode].process;
  for (const mode of modes) {
    const item = state.modes[mode];
    const explicit =
      (request.kind === "toggle" || request.kind === "off") &&
      request.mode === mode;
    const off =
      request.kind === "off-all" ||
      (explicit && (request.kind === "off" || toggleOff));
    const newSession = !!session && item.handledSession !== session;
    const denial = blocked(item.policy, power);
    if (
      newSession &&
      (request.kind === "poll" || explicit || request.kind === "off-all")
    )
      item.handledSession = session!;
    if (!denial && item.reason?.startsWith("Cannot read"))
      item.reason = undefined;
    if (item.process && (off || denial)) {
      await host.stop(mode, item.process);
      delete item.process;
      item.reason = off ? "Turned off" : denial;
      changed.add(mode);
      await save();
    }
    const manualStart = explicit && request.kind === "toggle" && !toggleOff;
    // Settings changes do not start processes. Startup is attempted once per app session.
    const startup = request.kind === "poll" && newSession && item.startup;
    if (!off && (manualStart || startup) && !item.process) {
      if (denial) item.reason = denial;
      else {
        item.process = await host.start(mode);
        item.reason = undefined;
        try {
          await save();
        } catch (error) {
          await host.stop(mode, item.process);
          delete item.process;
          throw error;
        }
        changed.add(mode);
      }
    }
  }
  await save();
  return { state, changed: [...changed] };
}
