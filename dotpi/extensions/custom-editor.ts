import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { CURSOR_MARKER, matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function stripAnsi(text: string): string {
  return text.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
}

function padToVisibleWidth(text: string, width: number): string {
  return text + " ".repeat(Math.max(0, width - visibleWidth(text)));
}

const SOFTWARE_CURSOR_START = "\x1b[7m";
const SOFTWARE_CURSOR_RESETS = ["\x1b[0m", "\x1b[27m"] as const;
const BEAM_CURSOR_SHAPE = "\x1b[6 q";
const RESET_CURSOR_SHAPE = "\x1b[0 q";
const SHOW_CURSOR = "\x1b[?25h";
const HIDE_CURSOR = "\x1b[?25l";
const ENABLE_FOCUS_EVENTS = "\x1b[?1004h";
const DISABLE_FOCUS_EVENTS = "\x1b[?1004l";
const FOCUS_IN = "\x1b[I";
const FOCUS_OUT = "\x1b[O";

type CursorRuntime = {
  write: (data: string) => void;
  setShowHardwareCursor: (show: boolean) => void;
  getShowHardwareCursor?: () => boolean | undefined;
};

type CursorCleanup = () => void;

function getCursorRuntime(tui: any): CursorRuntime | null {
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

function enableBeamCursorSupport(tui: any): CursorCleanup | null {
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

function addCursorMarkerBeforeSoftwareCursor(lines: string[]): void {
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

function stripSoftwareCursorWhenHardwareCursorIsUsed(lines: string[]): void {
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    if (!line?.includes(CURSOR_MARKER)) continue;

    lines[i] = stripSoftwareCursorAfterMarker(line);
    return;
  }
}

function removeLeadingVisibleSpace(text: string): string {
  let index = 0;
  let prefix = "";

  while (index < text.length) {
    const ansiMatch = text.slice(index).match(/^\x1b\[[0-?]*[ -/]*[@-~]/);
    if (!ansiMatch) break;

    prefix += ansiMatch[0];
    index += ansiMatch[0].length;
  }

  if (text[index] !== " ") return text;
  return prefix + text.slice(index + 1);
}

function applyBgToFullLine(text: string, width: number, bg: (text: string) => string): string {
  // The editor cursor contains an ANSI reset. If we wrap the whole line once,
  // that reset clears the background for the rest of the line. Apply the
  // background to each reset-delimited segment instead.
  return padToVisibleWidth(text, width)
    .split("\x1b[0m")
    .map((segment) => bg(segment))
    .join("\x1b[0m");
}

const BUILTIN_SLASH_COMMANDS = new Set([
  "settings",
  "model",
  "scoped-models",
  "export",
  "import",
  "share",
  "copy",
  "name",
  "session",
  "changelog",
  "hotkeys",
  "fork",
  "clone",
  "tree",
  "login",
  "logout",
  "new",
  "compact",
  "resume",
  "reload",
  "quit",
  // Hidden/debug commands handled by interactive mode.
  "debug",
  "arminsayshi",
  "dementedelves",
]);

function getSlashCommandName(text: string): string | undefined {
  const trimmed = text.trimStart();
  if (!trimmed.startsWith("/")) return undefined;

  const commandName = trimmed.slice(1).split(/\s+/, 1)[0];
  return commandName || undefined;
}

class CustomizedEditor extends CustomEditor {
  private activePromptMarkerColor: (text: string) => string;
  private inactivePromptMarkerColor: (text: string) => string;
  private editorBg: (text: string) => string;
  private cursorRuntime: CursorRuntime | null;
  private terminalFocused = true;
  private lastCursorState: "beam" | "hidden" | null = null;
  private requestRender: (() => void) | undefined;

  constructor(
    tui: any,
    theme: any,
    keybindings: any,
    activePromptMarkerColor: (text: string) => string,
    inactivePromptMarkerColor: (text: string) => string,
    editorBg: (text: string) => string,
    private isSlashCommand: (commandName: string) => boolean,
  ) {
    super(tui, theme, keybindings);
    this.activePromptMarkerColor = activePromptMarkerColor;
    this.inactivePromptMarkerColor = inactivePromptMarkerColor;
    this.editorBg = editorBg;
    this.cursorRuntime = getCursorRuntime(tui);
    this.requestRender = typeof tui?.requestRender === "function" ? () => tui.requestRender() : undefined;
  }
  setPaddingX(padding: number): void {
    // Keep enough left padding to draw the prompt marker without changing line width.
    super.setPaddingX(Math.max(1, padding));
  }

  render(width: number): string[] {
    const lines = super.render(width);
    this.syncHardwareCursorForRender(lines);

    // Remove the editor's top and bottom border lines while keeping content
    // and autocomplete lines intact.
    const withoutTopBorder = lines.slice(1);
    const bottomBorderIndex = withoutTopBorder.findIndex((line) => stripAnsi(line).startsWith("─"));
    if (bottomBorderIndex !== -1) {
      withoutTopBorder.splice(bottomBorderIndex, 1);
    }

    const editorLines = ["", ...withoutTopBorder, ""];
    const markerColor = this.focused && this.terminalFocused ? this.activePromptMarkerColor : this.inactivePromptMarkerColor;
    const marker = this.editorBg(markerColor("▎"));
    const contentWidth = Math.max(0, width - 1);

    return editorLines.map((line) =>
      truncateToWidth(
        marker + applyBgToFullLine(removeLeadingVisibleSpace(line), contentWidth, this.editorBg),
        width,
        "",
      ),
    );
  }

  handleInput(data: string): void {
    if (data === FOCUS_IN) {
      this.setTerminalFocused(true);
      return;
    }
    if (data === FOCUS_OUT) {
      this.setTerminalFocused(false);
      return;
    }

    const text = this.getText();
    const hasInput = text.trim().length > 0;
    const { line, col } = this.getCursor();
    const textBeforeCursor = this.getLines()[line]?.slice(0, col) ?? "";
    const hasInputAtCursor = /\S$/.test(textBeforeCursor);

    // Don't trigger file/autocomplete lookup when the current cursor token is empty.
    if (matchesKey(data, "tab") && !hasInputAtCursor) {
      return;
    }

    // If autocomplete/slash-command menu is open, Enter should accept the
    // highlighted completion only. Submitting remains a separate Enter press.
    // Avoid converting an empty prompt Enter into Tab/autocomplete acceptance.
    if (matchesKey(data, "enter") && hasInput && this.isShowingAutocomplete()) {
      super.handleInput("\t");
      return;
    }

    // Plain Enter submits known slash commands, otherwise inserts a newline.
    if (matchesKey(data, "enter")) {
      const commandName = getSlashCommandName(text);
      if (commandName && this.isSlashCommand(commandName)) {
        this.submitCurrentText();
      } else {
        this.insertTextAtCursor("\n");
      }
      return;
    }

    // Cmd+Enter in your Alacritty config sends CSI-u Alt+Enter.
    // Submit directly instead of passing through pi's follow-up keybinding.
    if (matchesKey(data, "alt+enter")) {
      this.submitCurrentText();
      return;
    }

    super.handleInput(data);
  }

  private submitCurrentText(): void {
    const text = this.getExpandedText().trim();
    if (!text) return;

    this.setText("");
    this.onSubmit?.(text);
  }

  private setTerminalFocused(focused: boolean): void {
    if (this.terminalFocused === focused) return;

    this.terminalFocused = focused;
    this.cursorRuntime?.setShowHardwareCursor(focused);
    this.writeCursorState(focused ? "beam" : "hidden");
    this.invalidate();
    this.requestRender?.();
  }

  private syncHardwareCursorForRender(lines: string[]): void {
    if (!this.cursorRuntime) return;

    // Pi's editor omits CURSOR_MARKER while autocomplete/slash-command menus are
    // open, which makes TUI hide the hardware cursor and leaves the reverse-video
    // software cursor visible. Add the marker back at the software cursor so the
    // hardware beam keeps working while dropdowns are shown.
    addCursorMarkerBeforeSoftwareCursor(lines);
    if (!lines.some((line) => line.includes(CURSOR_MARKER))) return;

    stripSoftwareCursorWhenHardwareCursorIsUsed(lines);
    this.cursorRuntime.setShowHardwareCursor(this.terminalFocused);
    this.writeCursorState(this.terminalFocused ? "beam" : "hidden");
  }

  private writeCursorState(state: "beam" | "hidden"): void {
    if (!this.cursorRuntime) return;
    if (state === "hidden" && this.lastCursorState === "hidden") return;

    // Reassert the beam on each focused render. Autocomplete/slash-command UI can
    // make the terminal/TUI show the cursor again after our previous shape write,
    // so caching the beam lets it get stuck as Alacritty's default block.
    this.cursorRuntime.write(state === "beam" ? SHOW_CURSOR + BEAM_CURSOR_SHAPE : HIDE_CURSOR);
    this.lastCursorState = state;
  }
}

export default function (pi: ExtensionAPI) {
  let cursorCleanup: CursorCleanup | null = null;

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      cursorCleanup = enableBeamCursorSupport(tui);
      return new CustomizedEditor(
        tui,
        theme,
        keybindings,
        (text: string) => ctx.ui.theme.fg("accent", text),
        (text: string) => ctx.ui.theme.fg("muted", text),
        (text: string) => ctx.ui.theme.bg("userMessageBg", text),
        (commandName: string) =>
          BUILTIN_SLASH_COMMANDS.has(commandName) || pi.getCommands().some((command) => command.name === commandName),
      );
    });
  });

  pi.on("session_shutdown", () => {
    try {
      cursorCleanup?.();
    } finally {
      cursorCleanup = null;
    }
  });
}
