import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const SETTINGS_KEY = "openaiCodexFastMode";
const SERVICE_TIER = "priority";
const STATUS_KEY = "fast-mode";
const STATUS_TEXT = "fast";

type Settings = Record<string, unknown>;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isOpenAICodexResponsesPayload(payload: unknown): payload is Record<string, unknown> {
  if (!isRecord(payload)) return false;

  const model = payload.model;
  if (typeof model === "string" && model.includes("codex")) return true;

  // Pi's OpenAI Codex Responses payload has this shape. This catches Codex-provider
  // requests even if a non-codex model id is routed through that provider.
  return (
    payload.stream === true &&
    typeof payload.instructions === "string" &&
    Array.isArray(payload.input) &&
    payload.tool_choice === "auto" &&
    "prompt_cache_key" in payload
  );
}

function expandHome(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

function getAgentDir(): string {
  return resolve(expandHome(process.env.PI_CODING_AGENT_DIR || "~/.pi/agent"));
}

function getSettingsPath(): string {
  return join(getAgentDir(), "settings.json");
}

function readSettings(): Settings {
  const settingsPath = getSettingsPath();
  try {
    const text = readFileSync(settingsPath, "utf8").trim();
    if (!text) return {};

    const parsed = JSON.parse(text);
    return isRecord(parsed) ? parsed : {};
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "ENOENT") return {};
    throw error;
  }
}

function readFastModeSetting(): boolean {
  const value = readSettings()[SETTINGS_KEY];
  return typeof value === "boolean" ? value : true;
}

function writeFastModeSetting(enabled: boolean): void {
  const settingsPath = getSettingsPath();
  const settings = readSettings();
  settings[SETTINGS_KEY] = enabled;

  mkdirSync(dirname(settingsPath), { recursive: true });
  writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`, "utf8");
}

export default function (pi: ExtensionAPI) {
  let fastModeEnabled = readFastModeSetting();
  let lastContext: ExtensionContext | undefined;

  function updateStatus(ctx = lastContext): void {
    if (!ctx?.hasUI) return;
    ctx.ui.setStatus(STATUS_KEY, fastModeEnabled ? STATUS_TEXT : undefined);
  }

  function setFastMode(enabled: boolean, ctx: ExtensionContext): void {
    fastModeEnabled = enabled;
    writeFastModeSetting(enabled);
    updateStatus(ctx);
    ctx.ui.notify(`Fast mode ${enabled ? "enabled" : "disabled"}`, "info");
  }

  pi.registerCommand("fast", {
    description: "Enable OpenAI Codex fast mode: /fast [on|off]",
    getArgumentCompletions: (prefix: string) => {
      const items = ["on", "off"].map((value) => ({ value, label: value }));
      const filtered = items.filter((item) => item.value.startsWith(prefix.trim()));
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args, ctx) => {
      lastContext = ctx;
      const arg = args.trim().toLowerCase();

      if (!arg || arg === "on") {
        setFastMode(true, ctx);
        return;
      }

      if (arg === "off") {
        setFastMode(false, ctx);
        return;
      }

      ctx.ui.notify("Usage: /fast [on|off]", "error");
    },
  });

  pi.on("session_start", (_event, ctx) => {
    lastContext = ctx;
    fastModeEnabled = readFastModeSetting();
    updateStatus(ctx);
  });

  pi.on("before_provider_request", (event) => {
    if (!fastModeEnabled) return;
    if (!isOpenAICodexResponsesPayload(event.payload)) return;

    return {
      ...event.payload,
      service_tier: SERVICE_TIER,
    };
  });
}
