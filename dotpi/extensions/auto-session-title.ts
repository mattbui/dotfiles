import { complete, type UserMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const MAX_TITLE_LENGTH = 100;
const MAX_TITLE_SOURCE_LENGTH = 12000;
const TITLE_ELLIPSIS = "..";
const TITLE_MODEL_PROVIDER = "openai-codex";
const TITLE_MODEL_ID = "gpt-5.4-mini";
const TITLE_FALLBACK_MODEL_PROVIDER = "openai";
const TITLE_GENERATION_SYSTEM_PROMPT = `You generate concise session titles for coding-agent conversations.

Given the user's first message, produce a short descriptive title.
Rules:
- Output only the title.
- Do not use quotes, markdown, prefixes, or trailing punctuation.
- Keep it under 5 words when possible.
- Prefer important file, command, or feature names over generic wording.`;

function isTmuxPane(): boolean {
  return !!process.env.TMUX && !!process.env.TMUX_PANE;
}

function sanitizeTitle(text: string): string {
  const normalized = text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
  if (normalized.length <= MAX_TITLE_LENGTH) return normalized;
  return `${normalized.slice(0, MAX_TITLE_LENGTH - TITLE_ELLIPSIS.length)}${TITLE_ELLIPSIS}`;
}

function sanitizeGeneratedTitle(text: string): string {
  let clean = text.replace(/^```(?:\w+)?\s*/i, "").replace(/\s*```$/i, "").trim();
  for (let i = 0; i < 2; i++) {
    clean = clean
      .replace(/^[-*]\s+/, "")
      .replace(/^title\s*:\s*/i, "")
      .replace(/^["'`“”‘’]+|["'`“”‘’]+$/g, "")
      .trim();
  }
  return sanitizeTitle(clean.replace(/[.!?]+$/g, ""));
}

function truncateTitleSource(text: string): string {
  if (text.length <= MAX_TITLE_SOURCE_LENGTH) return text;
  return `${text.slice(0, MAX_TITLE_SOURCE_LENGTH)}\n\n[First message truncated for title generation.]`;
}

function extractTextContent(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .map((part) => {
      if (!part || typeof part !== "object") return "";
      const maybeText = part as { type?: unknown; text?: unknown };
      return maybeText.type === "text" && typeof maybeText.text === "string" ? maybeText.text : "";
    })
    .filter(Boolean)
    .join("\n");
}

function getFirstUserMessage(ctx: { sessionManager: { getEntries(): unknown[] } }): string | undefined {
  for (const entry of ctx.sessionManager.getEntries()) {
    if (!entry || typeof entry !== "object") continue;
    const maybeEntry = entry as { type?: unknown; message?: { role?: unknown; content?: unknown } };
    if (maybeEntry.type !== "message") continue;
    if (maybeEntry.message?.role !== "user") continue;

    const text = extractTextContent(maybeEntry.message.content).trim();
    if (text) return text;
  }

  return undefined;
}

function getGeneratedTitleFromResponse(content: unknown): string {
  if (!Array.isArray(content)) return "";
  return content
    .map((part) => {
      if (!part || typeof part !== "object") return "";
      const maybeText = part as { type?: unknown; text?: unknown };
      return maybeText.type === "text" && typeof maybeText.text === "string" ? maybeText.text : "";
    })
    .filter(Boolean)
    .join("\n");
}

export default function (pi: ExtensionAPI) {
  let firstMessageCaptured = false;
  let titleGenerationStarted = false;
  let titleGenerationId = 0;
  let titleGenerationAbort: AbortController | undefined;
  let lastTitle: string | undefined;
  let pendingTmuxUpdate: Promise<void> | undefined;

  async function tmux(args: string[]): Promise<void> {
    if (!isTmuxPane()) return;
    await pi.exec("tmux", args, { timeout: 1000 }).catch(() => {});
  }

  async function isCurrentTmuxPaneFocused(): Promise<boolean> {
    const pane = process.env.TMUX_PANE;
    if (!pane) return false;

    const result = await pi
      .exec("tmux", ["display-message", "-p", "-t", pane, "#{pane_active} #{window_active}"], { timeout: 1000 })
      .catch(() => undefined);
    const output = typeof result?.stdout === "string" ? result.stdout : typeof result?.output === "string" ? result.output : "";
    return output.trim() === "1 1";
  }

  async function notifyTmuxAgentDone(): Promise<void> {
    if (!isTmuxPane()) return;
    if (await isCurrentTmuxPaneFocused()) return;

    process.stdout.write("\x07");
  }

  async function setTmuxPiState(title?: string): Promise<void> {
    const pane = process.env.TMUX_PANE;
    if (!pane) return;

    const cleanTitle = title ? sanitizeTitle(title) : "";
    lastTitle = cleanTitle || undefined;
    await tmux(["set-option", "-p", "-t", pane, "@pi_session_active", "1"]);
    if (cleanTitle) {
      await tmux(["set-option", "-p", "-t", pane, "@pi_session_name", cleanTitle]);
    } else {
      await tmux(["set-option", "-p", "-u", "-t", pane, "@pi_session_name"]);
    }
  }

  async function updateTmuxPiTitle(title: string): Promise<void> {
    const pane = process.env.TMUX_PANE;
    if (!pane) return;

    const cleanTitle = sanitizeTitle(title);
    if (!cleanTitle || cleanTitle === lastTitle) return;

    lastTitle = cleanTitle;
    await tmux(["set-option", "-p", "-t", pane, "@pi_session_name", cleanTitle]);
  }

  async function clearTmuxPiState(): Promise<void> {
    const pane = process.env.TMUX_PANE;
    if (!pane) return;

    await tmux(["set-option", "-p", "-u", "-t", pane, "@pi_session_active"]);
    await tmux(["set-option", "-p", "-u", "-t", pane, "@pi_session_name"]);
  }

  async function generateSessionTitle(firstMessage: string, ctx: ExtensionContext, signal: AbortSignal): Promise<string | undefined> {
    const model =
      ctx.modelRegistry.find(TITLE_MODEL_PROVIDER, TITLE_MODEL_ID) ??
      ctx.modelRegistry.find(TITLE_FALLBACK_MODEL_PROVIDER, TITLE_MODEL_ID);
    if (!model) return undefined;

    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok || !auth.apiKey || signal.aborted) return undefined;

    const message: UserMessage = {
      role: "user",
      content: [{ type: "text", text: truncateTitleSource(firstMessage) }],
      timestamp: Date.now(),
    };

    const response = await complete(
      model,
      { systemPrompt: TITLE_GENERATION_SYSTEM_PROMPT, messages: [message] },
      {
        apiKey: auth.apiKey,
        headers: auth.headers,
        maxTokens: 64,
        reasoningEffort: "minimal",
        signal,
      },
    );

    if (response.stopReason === "aborted") return undefined;
    return sanitizeGeneratedTitle(getGeneratedTitleFromResponse(response.content));
  }

  function startTitleGeneration(firstMessage: string, ctx: ExtensionContext): void {
    const text = firstMessage.trim();
    if (!text || titleGenerationStarted || pi.getSessionName()) return;

    titleGenerationStarted = true;
    const generationId = ++titleGenerationId;
    titleGenerationAbort?.abort();
    const abortController = new AbortController();
    titleGenerationAbort = abortController;

    void (async () => {
      const generatedTitle = await generateSessionTitle(text, ctx, abortController.signal);
      if (!generatedTitle) return;
      if (abortController.signal.aborted || generationId !== titleGenerationId) return;
      if (pi.getSessionName()) return;

      pi.setSessionName(generatedTitle);
      pendingTmuxUpdate = updateTmuxPiTitle(generatedTitle);
      await pendingTmuxUpdate;
    })()
      .catch(() => {})
      .finally(() => {
        if (generationId === titleGenerationId) titleGenerationAbort = undefined;
      });
  }

  pi.on("session_start", (_event, ctx) => {
    const sessionName = pi.getSessionName();
    const firstUserMessage = getFirstUserMessage(ctx);
    const title = sessionName || (firstUserMessage ? sanitizeTitle(firstUserMessage) : undefined);

    firstMessageCaptured = !!title;
    titleGenerationStarted = !!sessionName;

    if (isTmuxPane()) {
      pendingTmuxUpdate = setTmuxPiState(title);
      void pendingTmuxUpdate;
    }

    if (!sessionName && firstUserMessage) {
      startTitleGeneration(firstUserMessage, ctx);
    }
  });

  pi.on("input", async (event, ctx) => {
    if (firstMessageCaptured) return { action: "continue" };
    if (pi.getSessionName()) return { action: "continue" };

    const text = event.text.trim();
    if (!text || text.startsWith("/")) return { action: "continue" };

    const title = sanitizeTitle(text.split("\n")[0] ?? "");
    if (!title) return { action: "continue" };

    firstMessageCaptured = true;
    if (isTmuxPane()) {
      pendingTmuxUpdate = updateTmuxPiTitle(title);
      void pendingTmuxUpdate;
    }
    startTitleGeneration(text, ctx);
    return { action: "continue" };
  });

  pi.on("agent_end", async () => {
    await notifyTmuxAgentDone();
  });

  pi.on("session_shutdown", async () => {
    titleGenerationId++;
    titleGenerationAbort?.abort();
    titleGenerationAbort = undefined;

    await pendingTmuxUpdate?.catch(() => {});
    pendingTmuxUpdate = undefined;
    firstMessageCaptured = false;
    titleGenerationStarted = false;
    lastTitle = undefined;

    if (isTmuxPane()) {
      await clearTmuxPiState();
    }
  });
}
