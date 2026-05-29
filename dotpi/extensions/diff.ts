import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const POPUP_SCRIPT = path.join(os.homedir(), ".config", "tmux", "scripts", "revdiff-popup.sh");
const POPUP_TIMEOUT_MS = 6 * 60 * 60 * 1000;
const ANNOTATION_PROMPT_PREFIX = "I reviewed the current diff and added the following annotations:";

type ExecResult = {
  stdout?: string;
  stderr?: string;
  code?: number;
  killed?: boolean;
};

function splitArgs(input: string): string[] {
  const args: string[] = [];
  let current = "";
  let quote: "single" | "double" | undefined;
  let escaping = false;
  let inToken = false;

  for (const ch of input) {
    if (escaping) {
      current += ch;
      escaping = false;
      inToken = true;
      continue;
    }

    if (ch === "\\" && quote !== "single") {
      escaping = true;
      inToken = true;
      continue;
    }

    if (quote === "single") {
      if (ch === "'") quote = undefined;
      else current += ch;
      continue;
    }

    if (quote === "double") {
      if (ch === '"') quote = undefined;
      else current += ch;
      continue;
    }

    if (ch === "'") {
      quote = "single";
      inToken = true;
      continue;
    }

    if (ch === '"') {
      quote = "double";
      inToken = true;
      continue;
    }

    if (/\s/.test(ch)) {
      if (inToken) {
        args.push(current);
        current = "";
        inToken = false;
      }
      continue;
    }

    current += ch;
    inToken = true;
  }

  if (escaping) current += "\\";
  if (quote) throw new Error(`unterminated ${quote} quote`);
  if (inToken) args.push(current);

  return args;
}

async function readAnnotations(file: string): Promise<string> {
  try {
    return (await fs.readFile(file, "utf8")).trimEnd();
  } catch (error) {
    if (error && typeof error === "object" && "code" in error && error.code === "ENOENT") return "";
    throw error;
  }
}

function execErrorMessage(result: ExecResult): string {
  const stderr = result.stderr?.trim();
  if (stderr) return stderr;
  const stdout = result.stdout?.trim();
  if (stdout) return stdout;
  if (result.killed) return "revdiff popup timed out";
  return `revdiff popup exited with code ${result.code ?? "unknown"}`;
}

function shellQuote(arg: string): string {
  if (/^[A-Za-z0-9_./:=@%+-]+$/.test(arg)) return arg;
  return `'${arg.replace(/'/g, `'\\''`)}'`;
}

function formatReviewScope(args: string[], unstaged: boolean): string {
  if (unstaged) {
    const filters = args.length > 0 ? ` ${args.map(shellQuote).join(" ")}` : "";
    return `unstaged changes${filters}`;
  }
  if (args.length === 1 && args[0] === "HEAD") return "uncommitted changes";
  if (args.length === 1 && args[0] === "--staged") return "staged changes";
  return args.map(shellQuote).join(" ");
}

async function gitOutput(pi: ExtensionAPI, cwd: string, args: string[]): Promise<string | undefined> {
  const result = (await pi.exec("git", args, { cwd, timeout: 3000 }).catch(() => undefined)) as ExecResult | undefined;
  if (!result || result.code !== 0) return undefined;
  const stdout = result.stdout?.trim();
  return stdout || undefined;
}

async function buildReviewContext(pi: ExtensionAPI, cwd: string, revdiffArgs: string[], unstaged: boolean): Promise<string> {
  const lines = ["Review context:", `- scope: ${formatReviewScope(revdiffArgs, unstaged)}`];

  const branch =
    (await gitOutput(pi, cwd, ["branch", "--show-current"])) ??
    (await gitOutput(pi, cwd, ["rev-parse", "--abbrev-ref", "HEAD"]));
  if (branch) lines.push(`- current branch: ${branch}`);

  const commit = await gitOutput(pi, cwd, ["rev-parse", "--short", "HEAD"]);
  if (commit) lines.push(`- latest commit: ${commit}`);

  return lines.join("\n");
}

export default function diffExtension(pi: ExtensionAPI) {
  pi.registerCommand("diff", {
    description: "Open revdiff in a tmux popup",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/diff requires interactive mode", "error");
        return;
      }

      if (!process.env.TMUX) {
        ctx.ui.notify("/diff requires tmux", "error");
        return;
      }

      if (!ctx.isIdle()) {
        ctx.ui.notify("Wait for the current agent response to finish before opening /diff", "warning");
        return;
      }

      let revdiffArgs: string[];
      let unstaged = false;
      try {
        revdiffArgs = splitArgs(args.trim());
        unstaged = revdiffArgs.includes("--unstaged");
        if (unstaged) revdiffArgs = revdiffArgs.filter((arg) => arg !== "--unstaged");
        if (!unstaged && revdiffArgs.length === 0) revdiffArgs = ["HEAD"];
      } catch (error) {
        ctx.ui.notify(error instanceof Error ? error.message : "Failed to parse /diff arguments", "error");
        return;
      }

      const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "pi-revdiff-"));
      const outputFile = path.join(tempDir, "annotations.md");
      const reviewContext = await buildReviewContext(pi, ctx.cwd, revdiffArgs, unstaged);

      try {
        const result = (await pi.exec("sh", [POPUP_SCRIPT, "--output", outputFile, "--", ...revdiffArgs], {
          timeout: POPUP_TIMEOUT_MS,
        })) as ExecResult;

        const annotations = await readAnnotations(outputFile);
        const code = result.code ?? 0;
        if (code !== 0 && code !== 10 && annotations === "") {
          ctx.ui.notify(execErrorMessage(result), "error");
          return;
        }

        if (annotations === "") {
          ctx.ui.notify("No annotations captured", "info");
          return;
        }

        ctx.ui.setEditorText(`${ANNOTATION_PROMPT_PREFIX}\n\n${reviewContext}\n\nAnnotations:\n\n${annotations}\n`);
        ctx.ui.notify("Annotations loaded into editor. Edit/add comments, then submit when ready.", "info");
      } catch (error) {
        ctx.ui.notify(error instanceof Error ? error.message : "Failed to open revdiff popup", "error");
      } finally {
        await fs.rm(tempDir, { recursive: true, force: true }).catch(() => {});
      }
    },
  });
}
