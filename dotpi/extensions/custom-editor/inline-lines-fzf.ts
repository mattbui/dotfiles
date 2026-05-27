import type { CustomEditor, ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { extendedMatch, Fzf, type FzfResultItem } from "fzf";

const INLINE_LINES_FZF_WIDGET_KEY = "inline-lines-fzf";
const INLINE_LINES_FZF_DEFAULT_COMMAND =
  "rg --column --line-number --no-heading --color=never --hidden --follow --glob '!.git' --glob '!.src' --glob '!.venv' --glob '!.DS_Store' --glob '!.undodir*' '^'";
const INLINE_LINES_FZF_MAX_MATCHES = 200;
const INLINE_LINES_FZF_MAX_VISIBLE = 10;

interface InlineLineCandidate {
  raw: string;
  displayText: string;
  file: string;
  line: string;
  column: string;
  text: string;
  insertText: string;
}

interface InlineLineFzfMatch {
  candidate: InlineLineCandidate;
  positions: Set<number>;
}

interface InlineLineToken {
  query: string;
  token: string;
  line: number;
  startCol: number;
  endCol: number;
}

interface InlineLineFzfState extends InlineLineToken {
  active: boolean;
  selectedIndex: number;
  matches: InlineLineFzfMatch[];
}

function extractInlineLineToken(textBeforeCursor: string, line: number, cursorCol: number): InlineLineToken | null {
  const match = textBeforeCursor.match(/(^|.*\s)@@(.*)$/);
  if (!match || match.index === undefined) return null;

  const boundary = match[1] ?? "";
  const query = match[2] ?? "";
  // `@@` opens the line picker, but `@@ ` should close immediately.
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

function highlightPositions(text: string, positions: Set<number>, highlight: (text: string) => string): string {
  if (positions.size === 0) return text;

  let result = "";
  for (let i = 0; i < text.length; i++) {
    const char = text.charAt(i);
    result += positions.has(i) ? highlight(char) : char;
  }
  return result;
}

function padToVisibleWidth(text: string, width: number): string {
  return text + " ".repeat(Math.max(0, width - visibleWidth(text)));
}

function applyBgToFullLine(text: string, width: number, bg: (text: string) => string): string {
  return padToVisibleWidth(text, width)
    .split("\x1b[0m")
    .map((segment) => bg(segment))
    .join("\x1b[0m");
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

function parseLineCandidate(raw: string): InlineLineCandidate | null {
  const match = raw.match(/^(.*?):(\d+):(\d+):(.*)$/);
  if (!match) return null;

  const file = match[1] ?? "";
  const line = match[2] ?? "";
  const column = match[3] ?? "";
  const text = match[4] ?? "";
  if (!file || !line || !column) return null;

  return {
    raw,
    displayText: raw,
    file,
    line,
    column,
    text,
    insertText: `${file}:${line}`,
  };
}

export class InlineLinesFzfController {
  private candidates: InlineLineCandidate[] = [];
  private fzf: Fzf<InlineLineCandidate[]> | undefined;
  private loadPromise: Promise<void> | undefined;
  private loadError: string | null = null;
  private state: InlineLineFzfState | null = null;
  private widgetVisible = false;
  private dismissedTokenStartKey: string | null = null;
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
    return Boolean(extractInlineLineToken(currentLine.slice(0, col), line, col));
  }

  dispose(): void {
    this.hideWidget();
  }

  close(render = false): void {
    this.state = null;
    this.hideWidget();
    if (render) this.requestRender();
  }

  updateFromEditor(editor: CustomEditor): void {
    const { line, col } = editor.getCursor();
    const currentLine = editor.getLines()[line] ?? "";
    const token = extractInlineLineToken(currentLine.slice(0, col), line, col);

    if (!token) {
      this.dismissedTokenStartKey = null;
      this.close(false);
      return;
    }

    const tokenStartKey = this.getTokenStartKey(token);
    if (this.dismissedTokenStartKey === tokenStartKey) {
      this.close(false);
      return;
    }

    this.ensureLoaded();
    const previousSelected = this.state?.query === token.query ? this.state.selectedIndex : 0;
    const matches = this.getMatches(token.query);
    this.state = {
      ...token,
      active: true,
      selectedIndex: Math.max(0, Math.min(previousSelected, Math.max(0, matches.length - 1))),
      matches,
    };
    this.showWidget();
    this.requestRender();
  }

  handleInput(editor: CustomEditor, data: string): boolean {
    if (!this.state) return false;

    if (matchesKey(data, "escape")) {
      this.dismissedTokenStartKey = this.getTokenStartKey(this.state);
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
      this.moveSelection(-INLINE_LINES_FZF_MAX_VISIBLE, false);
      return true;
    }

    if (matchesKey(data, "pageDown")) {
      this.moveSelection(INLINE_LINES_FZF_MAX_VISIBLE, false);
      return true;
    }

    if (matchesKey(data, "enter")) {
      this.acceptSelection(editor);
      return true;
    }

    return false;
  }

  private ensureLoaded(): void {
    if (this.fzf || this.loadPromise) return;

    const customCommand = process.env.PI_FZF_RG_COMMAND?.trim();
    const command = customCommand || INLINE_LINES_FZF_DEFAULT_COMMAND;

    this.loadPromise = (async () => {
      if (!customCommand && !(await this.hasDefaultRipgrep())) {
        this.loadError = "ripgrep (rg) not found. Install ripgrep to use @@ search.";
        this.requestRender();
        return;
      }

      const result = await this.pi.exec("bash", ["-lc", command], { timeout: 10000 });
      if (result.code !== 0 && result.code !== 1) {
        this.loadError = result.stderr?.trim() || `ripgrep source command failed with exit ${result.code}`;
        this.requestRender();
        return;
      }

      this.candidates = result.stdout
        .split("\n")
        .filter(Boolean)
        .map(parseLineCandidate)
        .filter((match): match is InlineLineCandidate => Boolean(match));
      this.fzf = new Fzf(this.candidates, {
        selector: (match) => match.displayText,
        forward: false,
        match: extendedMatch,
        limit: INLINE_LINES_FZF_MAX_MATCHES,
      });
      this.loadError = null;
      if (this.state) {
        this.state.matches = this.getMatches(this.state.query);
        this.state.selectedIndex = Math.max(0, Math.min(this.state.selectedIndex, Math.max(0, this.state.matches.length - 1)));
        this.requestRender();
      }
    })().catch((error) => {
      this.loadError = error instanceof Error ? error.message : String(error);
      this.requestRender();
    });
  }

  private getMatches(query: string): InlineLineFzfMatch[] {
    if (!this.fzf) return [];

    if (!query) {
      return this.candidates.slice(0, INLINE_LINES_FZF_MAX_MATCHES).map((candidate) => ({
        candidate,
        positions: new Set<number>(),
      }));
    }

    const results: FzfResultItem<InlineLineCandidate>[] = this.fzf.find(query);
    return results.slice(0, INLINE_LINES_FZF_MAX_MATCHES).map((result) => ({
      candidate: result.item,
      positions: result.positions,
    }));
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
    const candidate = match?.candidate;
    if (!candidate) return;

    const insertText = `${candidate.insertText} `;
    const lines = [...editor.getLines()];
    const currentLine = lines[this.state.line] ?? "";
    lines[this.state.line] = currentLine.slice(0, this.state.startCol) + insertText + currentLine.slice(this.state.endCol);
    setEditorTextAndCursor(editor, lines, this.state.line, this.state.startCol + insertText.length);
    this.dismissedTokenStartKey = null;
    this.close(true);
    this.requestRender();
  }

  private showWidget(): void {
    if (this.widgetVisible) return;

    this.widgetVisible = true;
    this.ui.setWidget(
      INLINE_LINES_FZF_WIDGET_KEY,
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
    this.ui.setWidget(INLINE_LINES_FZF_WIDGET_KEY, undefined);
  }

  private getTokenStartKey(token: InlineLineToken): string {
    return `${token.line}:${token.startCol}`;
  }

  private render(width: number, theme: any): string[] {
    const state = this.state;
    if (!state) return [];

    const lines: string[] = [];
    const accent = (text: string) => theme.fg("accent", text);
    const dim = (text: string) => theme.fg("dim", text);
    const warning = (text: string) => theme.fg("warning", text);
    const selectedBg = (text: string) => theme.bg("selectedBg", text);

    lines.push(truncateToWidth(`${accent("@@")} ${state.query ? dim(state.query) : dim("type to fuzzy-filter ripgrep lines")}`, width, ""));

    if (this.loadError) {
      lines.push(truncateToWidth(warning(`ripgrep failed: ${this.loadError}`), width, ""));
      return lines;
    }

    if (!this.fzf) {
      lines.push(truncateToWidth(dim("loading ripgrep results…"), width, ""));
      return lines;
    }

    if (state.matches.length === 0) {
      lines.push(truncateToWidth(warning("no matches"), width, ""));
      return lines;
    }

    const visible = Math.min(INLINE_LINES_FZF_MAX_VISIBLE, state.matches.length);
    const startIndex = Math.max(0, Math.min(state.selectedIndex - Math.floor(visible / 2), state.matches.length - visible));
    const endIndex = Math.min(startIndex + visible, state.matches.length);

    for (let i = startIndex; i < endIndex; i++) {
      const match = state.matches[i];
      if (!match) continue;
      const selected = i === state.selectedIndex;
      const prefix = selected ? accent("→ ") : "  ";
      const highlighted = highlightPositions(match.candidate.displayText, match.positions, (text) => theme.fg("warning", theme.bold(text)));
      const text = selected ? accent(highlighted) : highlighted;
      const row = truncateToWidth(prefix + text, width, "");
      lines.push(selected ? applyBgToFullLine(row, width, selectedBg) : row);
    }

    const count = state.matches.length >= INLINE_LINES_FZF_MAX_MATCHES ? `${INLINE_LINES_FZF_MAX_MATCHES}+` : String(state.matches.length);
    lines.push(truncateToWidth(dim(`↑↓ navigate • enter select • esc close • ${state.selectedIndex + 1}/${count}`), width, ""));
    return lines;
  }
}
