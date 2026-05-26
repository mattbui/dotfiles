import { CURSOR_MARKER } from "@earendil-works/pi-tui";

const SOFTWARE_CURSOR_START = "\x1b[7m";
const SOFTWARE_CURSOR_RESETS = ["\x1b[0m", "\x1b[27m"] as const;
export const BEAM_CURSOR_SHAPE = "\x1b[6 q";
export const RESET_CURSOR_SHAPE = "\x1b[0 q";
export const SHOW_CURSOR = "\x1b[?25h";
export const HIDE_CURSOR = "\x1b[?25l";
const ENABLE_FOCUS_EVENTS = "\x1b[?1004h";
const DISABLE_FOCUS_EVENTS = "\x1b[?1004l";
export const FOCUS_IN = "\x1b[I";
export const FOCUS_OUT = "\x1b[O";

export type CursorRuntime = {
  write: (data: string) => void;
  setShowHardwareCursor: (show: boolean) => void;
  getShowHardwareCursor?: () => boolean | undefined;
};

export type CursorCleanup = () => void;

export function getCursorRuntime(tui: any): CursorRuntime | null {
  const terminal = tui?.terminal;
  if (typeof terminal?.write !== "function" || typeof tui?.setShowHardwareCursor !== "function") return null;

  const runtime: CursorRuntime = {
    write(data: string) {
      terminal.write(data);
    },
    setShowHardwareCursor(show: boolean) {
      tui.setShowHardwareCursor(show);
    },
  };

  if (typeof tui?.getShowHardwareCursor === "function") {
    runtime.getShowHardwareCursor = () => {
      const value = tui.getShowHardwareCursor();
      return typeof value === "boolean" ? value : undefined;
    };
  }

  return runtime;
}

export function enableBeamCursorSupport(tui: any): CursorCleanup | null {
  const runtime = getCursorRuntime(tui);
  if (!runtime) return null;

  const previousShowHardwareCursor = runtime.getShowHardwareCursor?.();
  runtime.setShowHardwareCursor(true);
  runtime.write(ENABLE_FOCUS_EVENTS + SHOW_CURSOR + BEAM_CURSOR_SHAPE);

  return () => {
    if (previousShowHardwareCursor !== undefined) {
      runtime.setShowHardwareCursor(previousShowHardwareCursor);
    }
    // Write this last so the shell always gets a visible, reset cursor after Pi exits.
    runtime.write(SHOW_CURSOR + RESET_CURSOR_SHAPE + DISABLE_FOCUS_EVENTS);
  };
}

function findSoftwareCursorReset(
  line: string,
  startIndex: number,
): { index: number; sequence: (typeof SOFTWARE_CURSOR_RESETS)[number] } | null {
  let firstReset: { index: number; sequence: (typeof SOFTWARE_CURSOR_RESETS)[number] } | null = null;

  for (const sequence of SOFTWARE_CURSOR_RESETS) {
    const index = line.indexOf(sequence, startIndex);
    if (index === -1) continue;
    if (!firstReset || index < firstReset.index) {
      firstReset = { index, sequence };
    }
  }

  return firstReset;
}

function stripSoftwareCursorAfterMarker(line: string): string {
  const markerIndex = line.indexOf(CURSOR_MARKER);
  if (markerIndex === -1) return line;

  const searchStart = markerIndex + CURSOR_MARKER.length;
  const cursorStart = line.indexOf(SOFTWARE_CURSOR_START, searchStart);
  if (cursorStart === -1) return line;

  const cursorContentStart = cursorStart + SOFTWARE_CURSOR_START.length;
  const reset = findSoftwareCursorReset(line, cursorContentStart);
  if (!reset) return line;

  return line.slice(0, cursorStart) + line.slice(cursorContentStart, reset.index) + line.slice(reset.index + reset.sequence.length);
}

export function hasCursorMarker(lines: string[]): boolean {
  return lines.some((line) => line.includes(CURSOR_MARKER));
}

export function addCursorMarkerBeforeSoftwareCursor(lines: string[]): void {
  if (lines.some((line) => line.includes(CURSOR_MARKER))) return;

  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    const cursorStart = line?.indexOf(SOFTWARE_CURSOR_START) ?? -1;
    if (cursorStart === -1) continue;

    const cursorContentStart = cursorStart + SOFTWARE_CURSOR_START.length;
    if (!findSoftwareCursorReset(line, cursorContentStart)) continue;

    lines[i] = line.slice(0, cursorStart) + CURSOR_MARKER + line.slice(cursorStart);
    return;
  }
}

export function stripSoftwareCursorWhenHardwareCursorIsUsed(lines: string[]): void {
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    if (!line?.includes(CURSOR_MARKER)) continue;

    lines[i] = stripSoftwareCursorAfterMarker(line);
    return;
  }
}
