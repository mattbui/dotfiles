import { mkdir, readFile, writeFile, rename, rm } from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";
import lockfile from "proper-lockfile";
import { initialState, parseState } from "./model";
import type { State } from "./model";

export async function withStore<T>(
  directory: string,
  run: (state: State, save: () => Promise<void>) => Promise<T>,
) {
  await mkdir(directory, { recursive: true, mode: 0o700 });
  const stateFile = path.join(directory, "state.json");
  const release = await lockfile.lock(stateFile, {
    realpath: false,
    stale: 30_000,
    update: 5000,
    retries: { retries: 40, minTimeout: 100, maxTimeout: 100, factor: 1 },
  });
  const temporary = path.join(directory, `state.${randomUUID()}.tmp`);
  try {
    let state: State;
    try {
      state = parseState(await readFile(stateFile, "utf8"));
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      state = initialState();
    }
    const save = async () => {
      await writeFile(temporary, JSON.stringify(state, null, 2), {
        mode: 0o600,
      });
      await rename(temporary, stateFile);
    };
    return await run(state, save);
  } finally {
    try {
      await rm(temporary, { force: true });
    } finally {
      await release();
    }
  }
}
