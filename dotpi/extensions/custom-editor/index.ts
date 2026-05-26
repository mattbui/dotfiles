import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth, type AutocompleteProvider } from "@earendil-works/pi-tui";
import {
  addCursorMarkerBeforeSoftwareCursor,
  BEAM_CURSOR_SHAPE,
  type CursorCleanup,
  type CursorRuntime,
  enableBeamCursorSupport,
  FOCUS_IN,
  FOCUS_OUT,
  getCursorRuntime,
  hasCursorMarker,
  HIDE_CURSOR,
  SHOW_CURSOR,
  stripSoftwareCursorWhenHardwareCursorIsUsed,
} from "./cursor.ts";
import { createAtAutocompleteSuppressingProvider, InlineFileFzfController } from "./inline-file-fzf.ts";
import { InlineRipgrepFzfController } from "./inline-ripgrep.ts";

function stripAnsi(text: string): string {
  return text.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
}

function padToVisibleWidth(text: string, width: number): string {
  return text + " ".repeat(Math.max(0, width - visibleWidth(text)));
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

function getTextBeforeCursor(editor: CustomEditor): string {
  const { line, col } = editor.getCursor();
  return editor.getLines()[line]?.slice(0, col) ?? "";
}

function isAtInlineAtTriggerBoundary(editor: CustomEditor): boolean {
  const textBeforeCursor = getTextBeforeCursor(editor);
  if (textBeforeCursor.length === 0) return true;
  return /\s$/.test(textBeforeCursor);
}

function isAtInlineRipgrepSecondAtTrigger(editor: CustomEditor): boolean {
  return /(^|\s)@$/.test(getTextBeforeCursor(editor));
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
    private inlineFileSearch: InlineFileFzfController,
    private inlineRipgrepSearch: InlineRipgrepFzfController,
  ) {
    super(tui, theme, keybindings);
    this.activePromptMarkerColor = activePromptMarkerColor;
    this.inactivePromptMarkerColor = inactivePromptMarkerColor;
    this.editorBg = editorBg;
    this.cursorRuntime = getCursorRuntime(tui);
    this.requestRender = typeof tui?.requestRender === "function" ? () => tui.requestRender() : undefined;
  }

  override setAutocompleteProvider(provider: AutocompleteProvider): void {
    super.setAutocompleteProvider(createAtAutocompleteSuppressingProvider(provider));
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

    if (this.inlineRipgrepSearch.handleInput(this, data)) {
      return;
    }

    if (this.inlineFileSearch.handleInput(this, data)) {
      return;
    }

    // Own @/@@ triggers instead of letting the built-in file autocomplete
    // consume them. This also makes @ at column 0 open reliably.
    if (data === "@" && isAtInlineRipgrepSecondAtTrigger(this)) {
      this.insertTextAtCursor("@");
      this.updateInlineSearches();
      return;
    }

    if (data === "@" && isAtInlineAtTriggerBoundary(this)) {
      this.insertTextAtCursor("@");
      this.updateInlineSearches();
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
      this.updateInlineSearches();
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
      this.updateInlineSearches();
      return;
    }

    // Cmd+Enter in your Alacritty config sends CSI-u Alt+Enter.
    // Submit directly instead of passing through pi's follow-up keybinding.
    if (matchesKey(data, "alt+enter")) {
      this.submitCurrentText();
      this.updateInlineSearches();
      return;
    }

    super.handleInput(data);
    this.updateInlineSearches();
  }

  private updateInlineSearches(): void {
    this.inlineRipgrepSearch.updateFromEditor(this);
    if (this.inlineRipgrepSearch.isActive() || this.inlineRipgrepSearch.hasTokenAtCursor(this)) {
      this.inlineFileSearch.close(false);
    } else {
      this.inlineFileSearch.updateFromEditor(this);
    }
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
    if (!hasCursorMarker(lines)) return;

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
  let inlineFileSearch: InlineFileFzfController | null = null;
  let inlineRipgrepSearch: InlineRipgrepFzfController | null = null;

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      cursorCleanup = enableBeamCursorSupport(tui);
      inlineFileSearch = new InlineFileFzfController(pi, ctx.cwd, ctx.ui, () => tui.requestRender());
      inlineRipgrepSearch = new InlineRipgrepFzfController(pi, ctx.ui, () => tui.requestRender());
      return new CustomizedEditor(
        tui,
        theme,
        keybindings,
        (text: string) => ctx.ui.theme.fg("accent", text),
        (text: string) => ctx.ui.theme.fg("muted", text),
        (text: string) => ctx.ui.theme.bg("userMessageBg", text),
        (commandName: string) =>
          BUILTIN_SLASH_COMMANDS.has(commandName) || pi.getCommands().some((command) => command.name === commandName),
        inlineFileSearch,
        inlineRipgrepSearch,
      );
    });
  });

  pi.on("session_shutdown", () => {
    try {
      inlineRipgrepSearch?.dispose();
      inlineFileSearch?.dispose();
      cursorCleanup?.();
    } finally {
      inlineRipgrepSearch = null;
      inlineFileSearch = null;
      cursorCleanup = null;
    }
  });
}
