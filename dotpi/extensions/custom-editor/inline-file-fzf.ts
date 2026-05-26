import { existsSync, statSync } from "node:fs";
import { join } from "node:path";
import type { CustomEditor, ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, type AutocompleteProvider } from "@earendil-works/pi-tui";
import { extendedMatch, Fzf, type FzfResultItem } from "fzf";

const INLINE_FILE_FZF_WIDGET_KEY = "inline-file-fzf";
const INLINE_FILE_FZF_FD_COMMAND =
  "fd --hidden --follow --type f --type d --exclude .git --exclude .DS_Store --exclude .src --exclude .venv --exclude '.undodir*'";
const INLINE_FILE_FZF_FIND_COMMAND =
  "find . \\( -path './.git' -o -path './.src' -o -path './.venv' -o -path './.undodir*' -o -name '.DS_Store' \\) -prune -o \\( -type f -o -type d \\) -print";
const INLINE_FILE_FZF_DEFAULT_COMMAND =
  `if command -v fd >/dev/null 2>&1; then ${INLINE_FILE_FZF_FD_COMMAND}; else ${INLINE_FILE_FZF_FIND_COMMAND}; fi`;
const INLINE_FILE_FZF_MAX_MATCHES = 200;
const INLINE_FILE_FZF_MAX_VISIBLE = 10;

interface InlineFzfCandidate {
  path: string;
  insertText: string;
  isDirectory: boolean;
}

interface InlineFzfToken {
  query: string;
  token: string;
  line: number;
  startCol: number;
  endCol: number;
}

interface InlineFzfMatch {
  candidate: InlineFzfCandidate;
  positions: Set<number>;
}

interface InlineFzfState extends InlineFzfToken {
  active: boolean;
  selectedIndex: number;
  matches: InlineFzfMatch[];
}

function normalizeCandidatePath(path: string): string | null {
  const normalized = path.trim().replace(/^\.\//, "").replace(/\/+$/, "");
  if (!normalized || normalized === ".") return null;
  return normalized;
}

export function createAtAutocompleteSuppressingProvider(current: AutocompleteProvider): AutocompleteProvider {
  return {
    async getSuggestions(lines, cursorLine, cursorCol, options) {
      const line = lines[cursorLine] ?? "";
      if (extractInlineFzfToken(line.slice(0, cursorCol), cursorLine, cursorCol)) {
        return null;
      }
      return current.getSuggestions(lines, cursorLine, cursorCol, options);
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      const line = lines[cursorLine] ?? "";
      if (extractInlineFzfToken(line.slice(0, cursorCol), cursorLine, cursorCol)) {
        return false;
      }
      return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
    },
  };
}

function extractInlineFzfToken(textBeforeCursor: string, line: number, cursorCol: number): InlineFzfToken | null {
  const match = textBeforeCursor.match(/(^|.*\s)@(.*)$/);
  if (!match || match.index === undefined) return null;

  const boundary = match[1] ?? "";
  const query = match[2] ?? "";
  // `@` opens the file picker, but `@ ` should close immediately.
  // Spaces are allowed after the first query character: `@foo bar`.
  if (/^\s/.test(query)) return null;

  const startCol = match.index + boundary.length;
  return {
    query,
    token: `@${query}`,
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

export class InlineFileFzfController {
  private candidates: InlineFzfCandidate[] = [];
  private candidateByPath = new Map<string, InlineFzfCandidate>();
  private fzf: Fzf<string[]> | undefined;
  private loadPromise: Promise<void> | undefined;
  private loadError: string | null = null;
  private state: InlineFzfState | null = null;
  private widgetVisible = false;
  private dismissedTokenStartKey: string | null = null;

  constructor(
    private pi: ExtensionAPI,
    private cwd: string,
    private ui: { setWidget: any },
    private requestRender: () => void,
  ) {}

  isActive(): boolean {
    return this.state?.active === true;
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
    const token = extractInlineFzfToken(currentLine.slice(0, col), line, col);

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
      this.moveSelection(-INLINE_FILE_FZF_MAX_VISIBLE, false);
      return true;
    }

    if (matchesKey(data, "pageDown")) {
      this.moveSelection(INLINE_FILE_FZF_MAX_VISIBLE, false);
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

    const command = process.env.PI_INLINE_FZF_COMMAND?.trim() || INLINE_FILE_FZF_DEFAULT_COMMAND;
    this.loadPromise = this.pi
      .exec("bash", ["-lc", command], { timeout: 10000 })
      .then((result) => {
        if (result.code !== 0) {
          this.loadError = result.stderr?.trim() || `file search command failed with exit ${result.code}`;
          this.requestRender();
          return;
        }

        this.candidates = result.stdout
          .split("\n")
          .map((line) => this.createCandidate(line))
          .filter((candidate): candidate is InlineFzfCandidate => Boolean(candidate));
        this.candidateByPath = new Map(this.candidates.map((candidate) => [candidate.path, candidate]));
        this.fzf = new Fzf(
          this.candidates.map((candidate) => candidate.path),
          { forward: false, match: extendedMatch },
        );
        this.loadError = null;
        if (this.state) {
          this.state.matches = this.getMatches(this.state.query);
          this.state.selectedIndex = Math.max(0, Math.min(this.state.selectedIndex, Math.max(0, this.state.matches.length - 1)));
          this.requestRender();
        }
      })
      .catch((error) => {
        this.loadError = error instanceof Error ? error.message : String(error);
        this.requestRender();
      });
  }

  private createCandidate(rawPath: string): InlineFzfCandidate | null {
    const path = normalizeCandidatePath(rawPath);
    if (!path) return null;

    let isDirectory = rawPath.trim().endsWith("/");
    try {
      const absolutePath = join(this.cwd, path);
      if (existsSync(absolutePath)) {
        isDirectory = statSync(absolutePath).isDirectory();
      }
    } catch {
      // Keep the best-effort directory guess from the command output.
    }

    return {
      path: isDirectory ? `${path}/` : path,
      insertText: isDirectory ? `${path}/` : path,
      isDirectory,
    };
  }

  private getMatches(query: string): InlineFzfMatch[] {
    if (!this.fzf) return [];

    if (!query) {
      return this.candidates.slice(0, INLINE_FILE_FZF_MAX_MATCHES).map((candidate) => ({
        candidate,
        positions: new Set<number>(),
      }));
    }

    const results: FzfResultItem<string>[] = this.fzf.find(query);
    return results
      .slice(0, INLINE_FILE_FZF_MAX_MATCHES)
      .map((result) => {
        const candidate = this.candidateByPath.get(result.item);
        if (!candidate) return null;
        return {
          candidate,
          positions: result.positions,
        };
      })
      .filter((match): match is InlineFzfMatch => Boolean(match));
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

    const lines = [...editor.getLines()];
    const currentLine = lines[this.state.line] ?? "";
    lines[this.state.line] = currentLine.slice(0, this.state.startCol) + candidate.insertText + currentLine.slice(this.state.endCol);
    setEditorTextAndCursor(editor, lines, this.state.line, this.state.startCol + candidate.insertText.length);
    this.dismissedTokenStartKey = null;
    this.close(true);
    this.requestRender();
  }

  private showWidget(): void {
    if (this.widgetVisible) return;

    this.widgetVisible = true;
    this.ui.setWidget(
      INLINE_FILE_FZF_WIDGET_KEY,
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
    this.ui.setWidget(INLINE_FILE_FZF_WIDGET_KEY, undefined);
  }

  private getTokenStartKey(token: InlineFzfToken): string {
    return `${token.line}:${token.startCol}`;
  }

  private render(width: number, theme: any): string[] {
    const state = this.state;
    if (!state) return [];

    const lines: string[] = [];
    const accent = (text: string) => theme.fg("accent", text);
    const muted = (text: string) => theme.fg("muted", text);
    const dim = (text: string) => theme.fg("dim", text);
    const warning = (text: string) => theme.fg("warning", text);
    const border = (text: string) => theme.fg("border", text);

    lines.push(truncateToWidth(`${accent("@")} ${state.query ? dim(state.query) : dim("type to filter files/dirs")}`, width, ""));

    if (this.loadError) {
      lines.push(truncateToWidth(warning(`file search failed: ${this.loadError}`), width, ""));
      return lines;
    }

    if (!this.fzf) {
      lines.push(truncateToWidth(dim("loading files…"), width, ""));
      return lines;
    }

    if (state.matches.length === 0) {
      lines.push(truncateToWidth(warning("no matches"), width, ""));
      return lines;
    }

    const visible = Math.min(INLINE_FILE_FZF_MAX_VISIBLE, state.matches.length);
    const startIndex = Math.max(0, Math.min(state.selectedIndex - Math.floor(visible / 2), state.matches.length - visible));
    const endIndex = Math.min(startIndex + visible, state.matches.length);

    for (let i = startIndex; i < endIndex; i++) {
      const match = state.matches[i];
      if (!match) continue;
      const candidate = match.candidate;
      const selected = i === state.selectedIndex;
      const prefix = selected ? accent("→ ") : "  ";
      const suffix = candidate.isDirectory ? border("/") : "";
      const displayPath = candidate.isDirectory ? candidate.path.slice(0, -1) : candidate.path;
      const highlighted = highlightPositions(displayPath, match.positions, (text) => theme.fg("accent", theme.bold(text)));
      const text = selected ? accent(highlighted) + suffix : highlighted + suffix;
      lines.push(truncateToWidth(prefix + text, width, ""));
    }

    const count = state.matches.length >= INLINE_FILE_FZF_MAX_MATCHES ? `${INLINE_FILE_FZF_MAX_MATCHES}+` : String(state.matches.length);
    lines.push(truncateToWidth(dim(`↑↓ navigate • enter select • esc close • ${state.selectedIndex + 1}/${count}`), width, ""));
    return lines;
  }
}
