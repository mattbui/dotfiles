import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const CUSTOM_TYPE = "commit-mode";
const MARKER_LABEL = "commit-start";
const WIDGET_ID = "commit-mode";
const VALID_FLAGS = new Set(["staged", "split", "push"]);

const COMMIT_PROMPT = `Help me commit the current git changes.

Flag behavior:
- staged: use only staged changes
- split: make multiple focused commits; do NOT mix unrelated changes into a single commit
- push: push after committing; if clear, proceed without asking

Inspect git status/diffs and recent commits. Show detected changes, plan, and proposed message(s) before committing.

Commit style: "type(scope): imperative lowercase subject". For large changes, include a concise bullet-list body. Types: "feat", "fix", "chore", "docs", "refactor", "test". Avoid generic scopes unless the repo uses them. Use "deps" for dependency updates and "repo" only for repo-wide changes.

If push is absent, ask before committing. Never force-push or do risky/destructive actions without explicit confirmation. Stop and ask if conflicts exist or anything is unclear.

Inputs:
- Flags: $FLAGS
- Extra instruction: $EXTRA_PROMPT`;

const SUMMARY_INSTRUCTIONS = `Summarize this commit context concisely.

Start with one sentence describing the commit attempt, for example: "User tried to commit the current changes."

Then include only the relevant points below:
- parsed flags and user instructions
- detected changes
- staging/grouping plan
- proposed commit message(s)
- commits created, with hashes if available
- whether anything was pushed and to which branch
- any unresolved issue or follow-up

Omit tool details, file-by-file diffs, and implementation commentary.`;

type CommitMarker = {
  entryId: string;
  createdAt?: number;
};

type Token = {
  value: string;
  index: number;
};

type ParsedCommitArgs =
  | {
      ok: true;
      flags: string[];
      extraPrompt: string;
    }
  | {
      ok: false;
      error: string;
    };

function getCommitEntryData(entry: unknown): { event?: unknown; createdAt?: unknown; markerId?: unknown; clearedAt?: unknown } | undefined {
  if (!entry || typeof entry !== "object") return undefined;

  const maybeEntry = entry as { type?: unknown; customType?: unknown; data?: unknown };
  if (maybeEntry.type !== "custom" || maybeEntry.customType !== CUSTOM_TYPE) return undefined;
  if (!maybeEntry.data || typeof maybeEntry.data !== "object") return undefined;

  return maybeEntry.data as { event?: unknown; createdAt?: unknown; markerId?: unknown; clearedAt?: unknown };
}

function deriveMarkerFromCurrentBranch(ctx: ExtensionContext): CommitMarker | undefined {
  let activeMarker: CommitMarker | undefined;

  for (const entry of ctx.sessionManager.getBranch()) {
    const data = getCommitEntryData(entry);
    if (!data) continue;

    if (data.event === "set") {
      activeMarker = {
        entryId: entry.id,
        createdAt: typeof data.createdAt === "number" ? data.createdAt : undefined,
      };
      continue;
    }

    if (data.event === "clear" && activeMarker) {
      if (typeof data.markerId !== "string" || data.markerId === activeMarker.entryId) {
        activeMarker = undefined;
      }
    }
  }

  return activeMarker;
}

function syncCommitWidget(ctx: ExtensionContext, marker: CommitMarker | undefined): void {
  if (!ctx.hasUI) return;

  if (marker) {
    ctx.ui.setWidget(
      WIDGET_ID,
      (_tui, theme) =>
        new Text(`${theme.fg("warning", "commit mode")} ${theme.fg("dim", "• /commit clear to clean up commit context")}`, 0, 0),
    );
  } else {
    ctx.ui.setWidget(WIDGET_ID, undefined);
  }
}

function startCommitSummarizingWidget(ctx: ExtensionContext): (() => void) | undefined {
  if (!ctx.hasUI) return undefined;

  const frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
  let frameIndex = 0;

  const render = () => {
    const frame = frames[frameIndex % frames.length];
    frameIndex++;
    ctx.ui.setWidget(WIDGET_ID, (_tui, theme) => new Text(theme.fg("dim", `${frame} Summarizing commit context...`), 0, 0));
  };

  render();
  const interval = setInterval(render, 120);
  return () => clearInterval(interval);
}

function isDefaultTreeVisibleEntry(entry: unknown): entry is { id: string; type: string } {
  if (!entry || typeof entry !== "object") return false;

  const maybeEntry = entry as { id?: unknown; type?: unknown };
  if (typeof maybeEntry.id !== "string" || typeof maybeEntry.type !== "string") return false;

  return !["label", "custom", "model_change", "thinking_level_change", "session_info"].includes(maybeEntry.type);
}

function findVisibleMarkerLabelTarget(ctx: ExtensionContext, markerId: string): string | undefined {
  let foundMarker = false;

  for (const entry of ctx.sessionManager.getBranch()) {
    if (!foundMarker) {
      if (entry.id === markerId) foundMarker = true;
      continue;
    }

    if (!isDefaultTreeVisibleEntry(entry)) continue;

    const label = ctx.sessionManager.getLabel(entry.id);
    if (!label || label === MARKER_LABEL) return entry.id;
  }

  return undefined;
}

function findEntryBeforeMarker(ctx: ExtensionContext, markerId: string): string | undefined {
  let previousId: string | undefined;

  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.id === markerId) return previousId;
    previousId = entry.id;
  }

  return undefined;
}

function ensureMarkerLabels(pi: ExtensionAPI, ctx: ExtensionContext, marker: CommitMarker): void {
  const visibleLabelTargetId = findVisibleMarkerLabelTarget(ctx, marker.entryId);
  if (visibleLabelTargetId && ctx.sessionManager.getLabel(visibleLabelTargetId) !== MARKER_LABEL) {
    pi.setLabel(visibleLabelTargetId, MARKER_LABEL);
  }
}

function tokenizeArgs(args: string): Token[] {
  const tokens: Token[] = [];
  const regex = /\S+/g;
  let match: RegExpExecArray | null;

  while ((match = regex.exec(args)) !== null) {
    tokens.push({ value: match[0], index: match.index });
  }

  return tokens;
}

function parseCommitArgs(args: string): ParsedCommitArgs {
  const trimmed = args.trim();
  if (!trimmed) return { ok: true, flags: [], extraPrompt: "" };

  const tokens = tokenizeArgs(args);
  const flags: string[] = [];
  let promptStart: number | undefined;

  for (const token of tokens) {
    if (promptStart === undefined && VALID_FLAGS.has(token.value)) {
      flags.push(token.value);
      continue;
    }

    if (promptStart === undefined) {
      promptStart = token.index;
      continue;
    }

    if (VALID_FLAGS.has(token.value)) {
      return {
        ok: false,
        error: `Flag "${token.value}" appears after freeform prompt text. Put flags before additional instructions.`,
      };
    }
  }

  return {
    ok: true,
    flags,
    extraPrompt: promptStart === undefined ? "" : args.slice(promptStart).trim(),
  };
}

function buildCommitPrompt(args: string, parsed: Extract<ParsedCommitArgs, { ok: true }>): string {
  const uniqueFlags = [...new Set(parsed.flags)];
  const flagsText = uniqueFlags.length > 0 ? uniqueFlags.join(", ") : "none";
  const extraPrompt = parsed.extraPrompt || "none";

  return COMMIT_PROMPT.replace("$ARGUMENTS", args.trim())
    .replace("$FLAGS", flagsText)
    .replace("$EXTRA_PROMPT", extraPrompt);
}

function notify(ctx: ExtensionContext, message: string, level: "info" | "warning" | "error" = "info"): void {
  if (ctx.hasUI) ctx.ui.notify(message, level);
}

async function createMarker(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<CommitMarker | undefined> {
  const createdAt = Date.now();

  pi.appendEntry(CUSTOM_TYPE, {
    event: "set",
    createdAt,
  });

  const entryId = ctx.sessionManager.getLeafId();
  if (!entryId) {
    notify(ctx, "Could not create commit marker", "error");
    return undefined;
  }

  const marker = { entryId, createdAt };
  ensureMarkerLabels(pi, ctx, marker);
  return marker;
}

async function chooseClearMode(ctx: ExtensionCommandContext): Promise<"clear" | "summarize" | "cancel"> {
  if (!ctx.hasUI) return "clear";

  const choice = await ctx.ui.select("Clean up commit context", [
    "Clear without summary",
    "Summarize then clear",
    "Cancel",
  ]);

  if (choice === "Summarize then clear") return "summarize";
  if (choice === "Cancel" || choice === undefined) return "cancel";
  return "clear";
}

export default function (pi: ExtensionAPI) {
  let marker: CommitMarker | undefined;

  function refresh(ctx: ExtensionContext, options: { backfillLabels?: boolean } = {}): void {
    marker = deriveMarkerFromCurrentBranch(ctx);
    if (marker && options.backfillLabels) ensureMarkerLabels(pi, ctx, marker);
    syncCommitWidget(ctx, marker);
  }

  pi.on("session_start", (_event, ctx) => {
    refresh(ctx, { backfillLabels: true });
  });

  pi.on("session_tree", (_event, ctx) => {
    refresh(ctx, { backfillLabels: true });
  });

  pi.on("message_end", (_event, ctx) => {
    refresh(ctx, { backfillLabels: true });
  });

  pi.on("session_shutdown", (_event, ctx) => {
    marker = undefined;
    syncCommitWidget(ctx, undefined);
  });

  pi.registerCommand("commit", {
    description: "Stage, commit, and optionally push changes ([staged] [split] [push] [extra instruction...] | clear)",
    handler: async (args, ctx) => {
      const trimmed = args.trim();

      if (trimmed === "clear") {
        await ctx.waitForIdle();
        refresh(ctx);

        if (!marker) {
          notify(ctx, "No active commit marker", "warning");
          return;
        }

        const activeMarker = marker;
        const beforeMarkerId = findEntryBeforeMarker(ctx, activeMarker.entryId);
        const targetId = beforeMarkerId ?? activeMarker.entryId;

        const mode = await chooseClearMode(ctx);
        if (mode === "cancel") return;

        const stopSummarizingWidget = mode === "summarize" ? startCommitSummarizingWidget(ctx) : undefined;

        let result: { cancelled: boolean };
        try {
          result = await ctx.navigateTree(targetId, {
            summarize: mode === "summarize",
            customInstructions: mode === "summarize" ? SUMMARY_INSTRUCTIONS : undefined,
            replaceInstructions: mode === "summarize",
            label: mode === "summarize" ? "commit-summary" : undefined,
          });
        } finally {
          stopSummarizingWidget?.();
        }

        if (result.cancelled) {
          syncCommitWidget(ctx, marker);
          return;
        }

        if (!beforeMarkerId) {
          pi.appendEntry(CUSTOM_TYPE, {
            event: "clear",
            markerId: activeMarker.entryId,
            clearedAt: Date.now(),
          });
        }

        refresh(ctx);
        notify(ctx, "Commit context cleaned up", "info");
        return;
      }

      if (trimmed.startsWith("clear ")) {
        notify(ctx, "Usage: /commit clear", "error");
        return;
      }

      const parsed = parseCommitArgs(args);
      if (!parsed.ok) {
        notify(ctx, parsed.error, "error");
        return;
      }

      await ctx.waitForIdle();
      refresh(ctx);

      if (!marker) {
        marker = await createMarker(pi, ctx);
        syncCommitWidget(ctx, marker);
      } else {
        ensureMarkerLabels(pi, ctx, marker);
        notify(ctx, "commit marker already active; using existing marker", "info");
      }

      if (!marker) return;

      pi.sendUserMessage(buildCommitPrompt(args, parsed));
    },
  });
}
