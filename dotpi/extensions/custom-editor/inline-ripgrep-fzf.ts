import type { CustomEditor, ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth } from "@earendil-works/pi-tui";

const INLINE_RG_WIDGET_KEY = "inline-ripgrep-fzf";
const INLINE_RG_DEFAULT_COMMAND =
  "rg --column --line-number --no-heading --color=always --smart-case --hidden --follow --glob '!.git' --glob '!.src' --glob '!.venv' --glob '!.DS_Store' --glob '!.undodir*'";
const INLINE_RG_MAX_VISIBLE = 10;
const INLINE_RG_DEBOUNCE_MS = 100;

interface InlineRgMatch {
  raw: string;
  file: string;
  line: string;
  column: string;
  insertText: string;
}

interface InlineRgToken {
  query: string;
  token: string;
  line: number;
  startCol: number;
  endCol: number;
}

interface InlineRgState extends InlineRgToken {
  active: boolean;
  selectedIndex: number;
  matches: InlineRgMatch[];
  loading: boolean;
  error: string | null;
}

function stripAnsi(text: string): string {
  return text.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function extractInlineRgToken(textBeforeCursor: string, line: number, cursorCol: number): InlineRgToken | null {
  const match = textBeforeCursor.match(/(^|\s)@@(.*)$/);
  if (!match || match.index === undefined) return null;

  const boundary = match[1] ?? "";
  const query = match[2] ?? "";
  // `@@` opens the ripgrep picker, but `@@ ` should close immediately.
  // Spaces are allowed after the first query character: `@@some text`.
  if (/^\s/.test(query)) return null;

  const startCol = match.index + boundary.length;
  return {
    query,
    token: `@@${query}`,
    line,
    startCol,
    endCol: cursorCol,
  };
}

function setEditorTextAndCursor(editor: CustomEditor, lines: string[], cursorLine: number, cursorCol: number): void {
  editor.setText(lines.join("\n"));

  const editorAny = editor as any;
  if (editorAny.state && Array.isArray(editorAny.state.lines)) {
    editorAny.state.cursorLine = Math.max(0, Math.min(cursorLine, editorAny.state.lines.length - 1));
    const currentLine = editorAny.state.lines[editorAny.state.cursorLine] ?? "";
    editorAny.state.cursorCol = Math.max(0, Math.min(cursorCol, currentLine.length));
    editorAny.preferredVisualCol = null;
    editorAny.snappedFromCursorCol = null;
  }
}

function parseRgLine(raw: string): InlineRgMatch | null {
  const plain = stripAnsi(raw);
  const parts = plain.split(":");
  if (parts.length < 4) return null;

  const file = parts[0];
  const line = parts[1];
  const column = parts[2];
  if (!file || !line || !column) return null;

  return {
    raw,
    file,
    line,
    column,
    insertText: `${file}:${line}`,
  };
}

export class InlineRipgrepFzfController {
  private state: InlineRgState | null = null;
  private widgetVisible = false;
  private dismissedTokenKey: string | null = null;
  private debounceTimer: ReturnType<typeof setTimeout> | undefined;
  private requestId = 0;
  private defaultRgAvailable: boolean | null = null;

  constructor(
    private pi: ExtensionAPI,
    private ui: { setWidget: any },
    private requestRender: () => void,
  ) {}

  isActive(): boolean {
    return this.state?.active === true;
  }

  hasTokenAtCursor(editor: CustomEditor): boolean {
    const { line, col } = editor.getCursor();
    const currentLine = editor.getLines()[line] ?? "";
    return Boolean(extractInlineRgToken(currentLine.slice(0, col), line, col));
  }

  dispose(): void {
    this.clearDebounce();
    this.hideWidget();
  }

  close(render = false): void {
    this.state = null;
    this.clearDebounce();
    this.hideWidget();
    if (render) this.requestRender();
  }

  updateFromEditor(editor: CustomEditor): void {
    const { line, col } = editor.getCursor();
    const currentLine = editor.getLines()[line] ?? "";
    const token = extractInlineRgToken(currentLine.slice(0, col), line, col);

    if (!token) {
      this.close(false);
      return;
    }

    const tokenKey = this.getTokenKey(token);
    if (this.dismissedTokenKey === tokenKey) {
      this.close(false);
      return;
    }

    const previous = this.state;
    const queryChanged = previous?.query !== token.query;
    const previousSelected = queryChanged ? 0 : previous?.selectedIndex ?? 0;
    const matches = queryChanged ? [] : previous?.matches ?? [];

    this.state = {
      ...token,
      active: true,
      selectedIndex: Math.max(0, Math.min(previousSelected, Math.max(0, matches.length - 1))),
      matches,
      loading: false,
      error: null,
    };

    this.showWidget();

    if (queryChanged) {
      this.scheduleSearch(token.query);
    }

    this.requestRender();
  }

  handleInput(editor: CustomEditor, data: string): boolean {
    if (!this.state) return false;

    if (matchesKey(data, "escape")) {
      this.dismissedTokenKey = this.getTokenKey(this.state);
      this.close(true);
      return true;
    }

    if (matchesKey(data, "up")) {
      this.moveSelection(-1);
      return true;
    }

    if (matchesKey(data, "down")) {
      this.moveSelection(1);
      return true;
    }

    if (matchesKey(data, "pageUp")) {
      this.moveSelection(-INLINE_RG_MAX_VISIBLE, false);
      return true;
    }

    if (matchesKey(data, "pageDown")) {
      this.moveSelection(INLINE_RG_MAX_VISIBLE, false);
      return true;
    }

    if (matchesKey(data, "enter")) {
      this.acceptSelection(editor);
      return true;
    }

    return false;
  }

  private scheduleSearch(query: string): void {
    this.clearDebounce();
    const state = this.state;
    if (!state) return;

    if (!query.trim()) {
      state.matches = [];
      state.loading = false;
      state.error = null;
      this.requestRender();
      return;
    }

    state.matches = [];
    state.selectedIndex = 0;
    state.loading = true;
    state.error = null;
    const id = ++this.requestId;

    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = undefined;
      void this.runSearch(id, query);
    }, INLINE_RG_DEBOUNCE_MS);
  }

  private async runSearch(id: number, query: string): Promise<void> {
    const customCommand = process.env.PI_INLINE_RG_COMMAND?.trim();

    try {
      if (!customCommand && !(await this.hasDefaultRipgrep())) {
        if (id !== this.requestId || !this.state || this.state.query !== query) return;
        this.state.matches = [];
        this.state.loading = false;
        this.state.error = "ripgrep (rg) not found. Install ripgrep to use @@ search.";
        this.requestRender();
        return;
      }

      const commandPrefix = customCommand || INLINE_RG_DEFAULT_COMMAND;
      const command = `${commandPrefix} -- ${shellQuote(query)}`;
      const result = await this.pi.exec("bash", ["-lc", command], { timeout: 10000 });
      if (id !== this.requestId || !this.state || this.state.query !== query) return;

      if (result.code !== 0 && result.code !== 1) {
        this.state.matches = [];
        this.state.error = result.stderr?.trim() || `ripgrep failed with exit ${result.code}`;
      } else {
        this.state.matches = result.stdout
          .split("\n")
          .filter(Boolean)
          .map(parseRgLine)
          .filter((match): match is InlineRgMatch => Boolean(match));
        this.state.error = null;
      }

      this.state.loading = false;
      this.state.selectedIndex = Math.max(0, Math.min(this.state.selectedIndex, Math.max(0, this.state.matches.length - 1)));
      this.requestRender();
    } catch (error) {
      if (id !== this.requestId || !this.state || this.state.query !== query) return;
      this.state.matches = [];
      this.state.loading = false;
      this.state.error = error instanceof Error ? error.message : String(error);
      this.requestRender();
    }
  }

  private async hasDefaultRipgrep(): Promise<boolean> {
    if (this.defaultRgAvailable !== null) return this.defaultRgAvailable;

    try {
      const result = await this.pi.exec("bash", ["-lc", "command -v rg >/dev/null 2>&1"], { timeout: 1000 });
      this.defaultRgAvailable = result.code === 0;
    } catch {
      this.defaultRgAvailable = false;
    }

    return this.defaultRgAvailable;
  }

  private moveSelection(delta: number, wrap = true): void {
    if (!this.state || this.state.matches.length === 0) return;

    if (wrap) {
      const total = this.state.matches.length;
      this.state.selectedIndex = (this.state.selectedIndex + delta + total) % total;
    } else {
      this.state.selectedIndex = Math.max(0, Math.min(this.state.matches.length - 1, this.state.selectedIndex + delta));
    }
    this.requestRender();
  }

  private acceptSelection(editor: CustomEditor): void {
    if (!this.state) return;
    const match = this.state.matches[this.state.selectedIndex];
    if (!match) return;

    const lines = [...editor.getLines()];
    const currentLine = lines[this.state.line] ?? "";
    lines[this.state.line] = currentLine.slice(0, this.state.startCol) + match.insertText + currentLine.slice(this.state.endCol);
    setEditorTextAndCursor(editor, lines, this.state.line, this.state.startCol + match.insertText.length);
    this.dismissedTokenKey = null;
    this.close(true);
    this.requestRender();
  }

  private showWidget(): void {
    if (this.widgetVisible) return;

    this.widgetVisible = true;
    this.ui.setWidget(
      INLINE_RG_WIDGET_KEY,
      (_tui: any, theme: any) => ({
        render: (width: number) => this.render(width, theme),
        invalidate: () => {},
      }),
      { placement: "belowEditor" },
    );
  }

  private hideWidget(): void {
    if (!this.widgetVisible) return;
    this.widgetVisible = false;
    this.ui.setWidget(INLINE_RG_WIDGET_KEY, undefined);
  }

  private clearDebounce(): void {
    if (!this.debounceTimer) return;
    clearTimeout(this.debounceTimer);
    this.debounceTimer = undefined;
  }

  private getTokenKey(token: InlineRgToken): string {
    return `${token.line}:${token.startCol}:${token.endCol}:${token.token}`;
  }

  private render(width: number, theme: any): string[] {
    const state = this.state;
    if (!state) return [];

    const lines: string[] = [];
    const accent = (text: string) => theme.fg("accent", text);
    const dim = (text: string) => theme.fg("dim", text);
    const warning = (text: string) => theme.fg("warning", text);

    lines.push(truncateToWidth(`${accent("@@")} ${state.query ? dim(state.query) : dim("type to search file contents")}`, width, ""));

    if (state.error) {
      lines.push(truncateToWidth(warning(`ripgrep failed: ${state.error}`), width, ""));
      return lines;
    }

    if (!state.query.trim()) {
      return lines;
    }

    if (state.loading) {
      lines.push(truncateToWidth(dim("searching…"), width, ""));
      return lines;
    }

    if (state.matches.length === 0) {
      lines.push(truncateToWidth(warning("no matches"), width, ""));
      return lines;
    }

    const visible = Math.min(INLINE_RG_MAX_VISIBLE, state.matches.length);
    const startIndex = Math.max(0, Math.min(state.selectedIndex - Math.floor(visible / 2), state.matches.length - visible));
    const endIndex = Math.min(startIndex + visible, state.matches.length);

    for (let i = startIndex; i < endIndex; i++) {
      const match = state.matches[i];
      if (!match) continue;
      const selected = i === state.selectedIndex;
      const prefix = selected ? accent("→ ") : "  ";
      lines.push(truncateToWidth(prefix + match.raw, width, ""));
    }

    lines.push(truncateToWidth(dim(`↑↓ navigate • enter select • esc close • ${state.selectedIndex + 1}/${state.matches.length}`), width, ""));
    return lines;
  }
}
