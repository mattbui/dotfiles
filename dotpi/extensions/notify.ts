/**
 * Agent completion notifications.
 *
 * Behavior on every `agent_end` event:
 * - Always sends a terminal bell (`\x07`).
 * - Sends a macOS notification when the user is likely not looking at this pi session.
 * - Skips the macOS notification when this tmux window is focused in an attached session
 *   and the terminal app is frontmost. Pane focus is intentionally ignored: if any pane in
 *   the current tmux window is active, the user is considered present for this session.
 *
 * The macOS notification title is `pi: <session name>` when a session name exists, or `pi`
 * otherwise. The notification body is a truncated preview of the last assistant response.
 *
 * `PI_NOTIFY_TERMINAL_APP` can be set when the terminal app is not Alacritty.
 */
import type { AssistantMessage, TextContent } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const TERMINAL_APP_NAME = process.env.PI_NOTIFY_TERMINAL_APP || "Alacritty";
const NOTIFICATION_TITLE_PREFIX = "pi";
const MAX_NOTIFICATION_BODY_LENGTH = 220;

function isTmuxPane(): boolean {
  return !!process.env.TMUX && !!process.env.TMUX_PANE;
}

function getExecOutput(result: unknown): string {
  if (!result || typeof result !== "object") return "";
  const maybeResult = result as { stdout?: unknown; output?: unknown };
  if (typeof maybeResult.stdout === "string") return maybeResult.stdout;
  if (typeof maybeResult.output === "string") return maybeResult.output;
  return "";
}

function parseTmuxFlag(value: string): boolean | undefined {
  if (value === "1") return true;
  if (value === "0") return false;
  return undefined;
}

function parseTmuxCount(value: string): number | undefined {
  const count = Number(value);
  return Number.isFinite(count) ? count : undefined;
}

function sanitizeNotificationText(text: string): string {
  return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

function truncateNotificationText(text: string): string {
  const clean = sanitizeNotificationText(text);
  if (clean.length <= MAX_NOTIFICATION_BODY_LENGTH) return clean;
  return `${clean.slice(0, Math.max(0, MAX_NOTIFICATION_BODY_LENGTH - 1))}…`;
}

function isAssistantMessage(message: unknown): message is AssistantMessage {
  if (!message || typeof message !== "object") return false;
  const maybeMessage = message as { role?: unknown; content?: unknown };
  return maybeMessage.role === "assistant" && Array.isArray(maybeMessage.content);
}

function getAssistantText(message: AssistantMessage): string {
  return message.content
    .filter((part): part is TextContent => part.type === "text")
    .map((part) => part.text)
    .join("\n");
}

async function getCurrentTmuxFocusState(pi: ExtensionAPI): Promise<{ windowFocused: boolean; sessionAttached: boolean }> {
  const pane = process.env.TMUX_PANE;
  if (!pane) return { windowFocused: false, sessionAttached: false };

  const result = await pi
    .exec(
      "tmux",
      ["display-message", "-p", "-t", pane, "#{window_active}\t#{window_visible}\t#{session_attached}"],
      { timeout: 1000 },
    )
    .catch(() => undefined);

  const [windowActiveRaw = "", windowVisibleRaw = "", sessionAttachedRaw = ""] = getExecOutput(result).trim().split("\t");
  const windowActive = parseTmuxFlag(windowActiveRaw) === true;
  // `window_visible` is not present in every tmux build/version. If it is unavailable,
  // fall back to `window_active`, which is the closest portable signal for this session.
  const windowVisible = parseTmuxFlag(windowVisibleRaw) ?? windowActive;
  const sessionAttached = (parseTmuxCount(sessionAttachedRaw) ?? 0) > 0;

  return { windowFocused: windowActive && windowVisible, sessionAttached };
}

async function getFrontmostApplication(pi: ExtensionAPI): Promise<string | undefined> {
  if (process.platform !== "darwin") return undefined;

  const result = await pi
    .exec("osascript", ["-e", 'tell application "System Events" to get name of first application process whose frontmost is true'], {
      timeout: 1000,
    })
    .catch(() => undefined);

  const appName = getExecOutput(result).trim();
  return appName || undefined;
}

async function isTerminalFocused(pi: ExtensionAPI): Promise<boolean | undefined> {
  const frontmostApplication = await getFrontmostApplication(pi);
  if (!frontmostApplication) return undefined;
  return frontmostApplication.toLowerCase() === TERMINAL_APP_NAME.toLowerCase();
}

async function sendMacosNotification(pi: ExtensionAPI, title: string, body: string): Promise<void> {
  if (process.platform !== "darwin") return;

  await pi
    .exec(
      "osascript",
      [
        "-e",
        "on run argv",
        "-e",
        "display notification (item 1 of argv) with title (item 2 of argv)",
        "-e",
        "end run",
        "--",
        body,
        title,
      ],
      { timeout: 3000 },
    )
    .catch(() => {});
}

function buildNotificationTitle(pi: ExtensionAPI, ctx: ExtensionContext): string {
  const sessionName = pi.getSessionName() || ctx.sessionManager.getSessionName();
  return sanitizeNotificationText(sessionName ? `${NOTIFICATION_TITLE_PREFIX}: ${sessionName}` : NOTIFICATION_TITLE_PREFIX);
}

function buildNotificationBody(responseText?: string): string {
  return responseText ? truncateNotificationText(responseText) : "Agent done";
}

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async (event, ctx) => {
    // Always send the terminal bell.
    process.stdout.write("\x07");

    const tmuxFocus = isTmuxPane()
      ? await getCurrentTmuxFocusState(pi)
      : { windowFocused: false, sessionAttached: false };
    const terminalFocused = await isTerminalFocused(pi);

    if (isTmuxPane()) {
      // Skip macOS notification when this tmux window is focused in an attached session
      // and the terminal app is focused (or app focus cannot be determined). Pane focus
      // does not matter: another active pane in the same window should still suppress it.
      if (tmuxFocus.windowFocused && tmuxFocus.sessionAttached && terminalFocused !== false) return;
    } else if (terminalFocused !== false) {
      return;
    }

    const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
    const responseText = lastAssistant ? getAssistantText(lastAssistant) : undefined;
    await sendMacosNotification(pi, buildNotificationTitle(pi, ctx), buildNotificationBody(responseText));
  });
}
