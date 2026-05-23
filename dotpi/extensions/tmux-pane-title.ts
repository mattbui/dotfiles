import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MAX_TITLE_LENGTH = 100;
const TITLE_ELLIPSIS = "..";
const AGENT_DONE_MESSAGE = "pi done";

function isTmuxPane(): boolean {
	return !!process.env.TMUX && !!process.env.TMUX_PANE;
}

function sanitizeTitle(text: string): string {
	const normalized = text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
	if (normalized.length <= MAX_TITLE_LENGTH) return normalized;
	return `${normalized.slice(0, MAX_TITLE_LENGTH - TITLE_ELLIPSIS.length)}${TITLE_ELLIPSIS}`;
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

		const text = sanitizeTitle(extractTextContent(maybeEntry.message.content));
		if (text) return text;
	}

	return undefined;
}

export default function (pi: ExtensionAPI) {
	let firstMessageCaptured = false;
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

		const message = lastTitle ? `${AGENT_DONE_MESSAGE}: ${lastTitle}` : AGENT_DONE_MESSAGE;
		process.stdout.write("\x07");
		await tmux(["display-message", message]);
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

	pi.on("session_start", (_event, ctx) => {
		if (!isTmuxPane()) return;

		const sessionName = pi.getSessionName();
		const firstUserMessage = getFirstUserMessage(ctx);
		const title = sessionName || firstUserMessage;

		firstMessageCaptured = !!title;
		pendingTmuxUpdate = setTmuxPiState(title);
		void pendingTmuxUpdate;
	});

	pi.on("input", async (event) => {
		if (!isTmuxPane()) return { action: "continue" };
		if (firstMessageCaptured) return { action: "continue" };
		if (pi.getSessionName()) return { action: "continue" };

		const text = event.text.trim();
		if (!text || text.startsWith("/")) return { action: "continue" };

		const title = sanitizeTitle(text.split("\n")[0] ?? "");
		if (!title) return { action: "continue" };

		firstMessageCaptured = true;
		pendingTmuxUpdate = updateTmuxPiTitle(title);
		void pendingTmuxUpdate;
		return { action: "continue" };
	});

	pi.on("agent_end", async () => {
		await notifyTmuxAgentDone();
	});

	pi.on("session_shutdown", async () => {
		if (!isTmuxPane()) return;

		await pendingTmuxUpdate?.catch(() => {});
		pendingTmuxUpdate = undefined;
		firstMessageCaptured = false;
		lastTitle = undefined;
		await clearTmuxPiState();
	});
}
