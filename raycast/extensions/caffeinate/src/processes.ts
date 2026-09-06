import { execFile, spawn } from "node:child_process";
import { promisify } from "node:util";
import { setTimeout as delay } from "node:timers/promises";
import { flags, ownedProcess, parsePower } from "./model";
import type { Mode, ProcessIdentity } from "./model";

const exec = promisify(execFile);
const uid = process.getuid!();
export async function command(file: string, args: string[]) {
  return (
    await exec(file, args, {
      timeout: 5000,
      maxBuffer: 4 * 1024 * 1024,
      env: { ...process.env, LC_ALL: "C" },
    })
  ).stdout;
}

export function parseIdentity(
  pid: number,
  output: string,
): ProcessIdentity | null {
  const match = output
    .trim()
    .match(
      /^(\w{3}\s+\w{3}\s+\d+\s+\d{2}:\d{2}:\d{2}\s+\d{4})\s+(\d+)\s+(.+)$/,
    );
  return match
    ? {
        pid,
        started: match[1].replace(/\s+/g, " "),
        uid: Number(match[2]),
        command: match[3],
      }
    : null;
}

export async function identity(pid: number): Promise<ProcessIdentity | null> {
  try {
    const output = await command("/bin/ps", [
      "-ww",
      "-p",
      String(pid),
      "-o",
      "lstart=,uid=,command=",
    ]);
    const result = parseIdentity(pid, output);
    if (!result && output.trim())
      throw new Error("Cannot parse process identity");
    return result;
  } catch (error) {
    // ps returns 1 when the PID no longer exists. Permission and execution failures remain errors.
    if (
      (error as { code?: number; stdout?: string; stderr?: string }).code ===
        1 &&
      !(error as { stdout?: string }).stdout?.trim() &&
      !(error as { stderr?: string }).stderr?.trim()
    )
      return null;
    throw error;
  }
}

export const processHost = {
  async alive(mode: Mode, expected: ProcessIdentity) {
    return ownedProcess(mode, expected, await identity(expected.pid), uid);
  },
  async start(mode: Mode): Promise<ProcessIdentity> {
    const child = spawn("/usr/bin/caffeinate", [flags[mode]], {
      detached: true,
      stdio: "ignore",
    });
    await new Promise<void>((resolve, reject) => {
      child.once("spawn", resolve);
      child.once("error", reject);
    });
    child.unref();
    try {
      await delay(80);
      const actual = await identity(child.pid!);
      if (
        !actual ||
        actual.uid !== uid ||
        actual.command !== `/usr/bin/caffeinate ${flags[mode]}`
      )
        throw new Error("Caffeinate did not start");
      return actual;
    } catch (error) {
      child.kill("SIGTERM");
      throw error;
    }
  },
  async stop(mode: Mode, expected: ProcessIdentity) {
    if (!(await this.alive(mode, expected))) return;
    try {
      process.kill(expected.pid, "SIGTERM");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ESRCH") throw error;
    }
    for (let count = 0; count < 10; count++) {
      if (!(await this.alive(mode, expected))) return;
      await delay(30);
    }
    throw new Error(`The ${mode} process has not stopped yet`);
  },
};

export async function power() {
  try {
    return parsePower(await command("/usr/bin/pmset", ["-g", "batt"]));
  } catch {
    return null;
  }
}

export async function raycastSession(): Promise<string | null> {
  const output = await command("/bin/ps", [
    "-ww",
    "-axo",
    "pid=,lstart=,uid=,command=",
  ]);
  for (const line of output.split("\n")) {
    const match = line.trim().match(/^(\d+)\s+(.+)$/);
    if (!match) continue;
    const record = parseIdentity(Number(match[1]), match[2]);
    if (
      record?.uid === uid &&
      /^\/.*\/Raycast\.app\/Contents\/MacOS\/Raycast(?:\s|$)/.test(
        record.command,
      )
    ) {
      return `${record.pid}:${record.started}`;
    }
  }
  return null;
}
