import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

function sanitizeStatusText(text: string): string {
  return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
  return `${Math.round(count / 1000000)}M`;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          let totalInput = 0;
          let totalOutput = 0;
          let totalCacheRead = 0;
          let totalCacheWrite = 0;
          let totalCost = 0;

          for (const entry of ctx.sessionManager.getEntries()) {
            if (entry.type === "message" && entry.message.role === "assistant") {
              const message = entry.message as AssistantMessage;
              totalInput += message.usage.input;
              totalOutput += message.usage.output;
              totalCacheRead += message.usage.cacheRead;
              totalCacheWrite += message.usage.cacheWrite;
              totalCost += message.usage.cost.total;
            }
          }

          let pwd = ctx.sessionManager.getCwd();
          const home = process.env.HOME || process.env.USERPROFILE;
          if (home && pwd.startsWith(home)) pwd = `~${pwd.slice(home.length)}`;

          const separator = theme.fg("dim", " • ");
          const branch = footerData.getGitBranch();
          const sessionName = ctx.sessionManager.getSessionName();
          const pwdLineParts = [theme.fg("dim", pwd)];
          if (branch) {
            pwdLineParts.push(theme.fg("dim", " ("), theme.fg("success", branch), theme.fg("dim", ")"));
          }
          if (sessionName) {
            pwdLineParts.push(separator, theme.fg("muted", sessionName));
          }

          const modelName = ctx.model?.id || "no-model";
          const modelParts: string[] = [];
          if (ctx.model) {
            modelParts.push(theme.fg("dim", `(${ctx.model.provider}) `));
          }
          modelParts.push(theme.fg("accent", modelName));
          if (ctx.model?.reasoning) {
            const thinkingLevel = pi.getThinkingLevel() || "off";
            const thinkingLabel = thinkingLevel === "off" ? "thinking off" : thinkingLevel;
            let thinkingText = theme.fg("muted", thinkingLabel);
            if (thinkingLevel === "off") thinkingText = theme.fg("thinkingOff", thinkingLabel);
            else if (thinkingLevel === "minimal") thinkingText = theme.fg("thinkingMinimal", thinkingLabel);
            else if (thinkingLevel === "low") thinkingText = theme.fg("thinkingLow", thinkingLabel);
            else if (thinkingLevel === "medium") thinkingText = theme.fg("thinkingMedium", thinkingLabel);
            else if (thinkingLevel === "high") thinkingText = theme.fg("thinkingHigh", thinkingLabel);
            else if (thinkingLevel === "xhigh") thinkingText = theme.fg("thinkingXhigh", thinkingLabel);
            modelParts.push(separator, thinkingText);
          }

          const statsParts: string[] = [];
          if (totalInput) statsParts.push(theme.fg("muted", `↑${formatTokens(totalInput)}`));
          if (totalOutput) statsParts.push(theme.fg("muted", `↓${formatTokens(totalOutput)}`));
          if (totalCacheRead) statsParts.push(theme.fg("dim", `R${formatTokens(totalCacheRead)}`));
          if (totalCacheWrite) statsParts.push(theme.fg("dim", `W${formatTokens(totalCacheWrite)}`));

          const usingSubscription = ctx.model ? ctx.modelRegistry.isUsingOAuth(ctx.model) : false;
          if (totalCost || usingSubscription) {
            statsParts.push(theme.fg("warning", `$${totalCost.toFixed(3)}`) + (usingSubscription ? theme.fg("dim", " (sub)") : ""));
          }

          const contextUsage = ctx.getContextUsage();
          const contextWindow = contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const contextPercentValue = contextUsage?.percent ?? 0;
          const contextPercent = contextUsage?.percent !== null && contextUsage?.percent !== undefined ? contextPercentValue.toFixed(1) : "?";
          const contextDisplay = contextPercent === "?" ? `?/${formatTokens(contextWindow)} (auto)` : `${contextPercent}%/${formatTokens(contextWindow)} (auto)`;
          if (contextPercentValue > 90) statsParts.push(theme.fg("error", contextDisplay));
          else if (contextPercentValue > 70) statsParts.push(theme.fg("warning", contextDisplay));
          else statsParts.push(theme.fg("muted", contextDisplay));

          const statsLine = statsParts.join(" ");
          const modelAndStatsLine = statsLine ? `${modelParts.join("")}${separator}${statsLine}` : modelParts.join("");
          const lines = [
            truncateToWidth(pwdLineParts.join(""), width, theme.fg("dim", "...")),
            truncateToWidth(modelAndStatsLine, width, theme.fg("dim", "...")),
            "",
          ];

          const extensionStatuses = footerData.getExtensionStatuses();
          if (extensionStatuses.size > 0) {
            const statusLine = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, text]) => sanitizeStatusText(text))
              .join(" ");
            lines.push(truncateToWidth(statusLine, width, theme.fg("dim", "...")));
          }

          return lines;
        },
      };
    });
  });
}
