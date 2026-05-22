import { DynamicBorder, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Container, type SelectItem, SelectList, Text } from "@earendil-works/pi-tui";

const levels = ["off", "minimal", "low", "medium", "high", "xhigh"] as const;
type ThinkingLevel = (typeof levels)[number];

export default function (pi: ExtensionAPI) {
  const command = {
    description: "Set reasoning/thinking level: off|minimal|low|medium|high|xhigh",
    getArgumentCompletions: (prefix: string) => {
      const items = levels.map((level) => ({ value: level, label: level }));
      const filtered = items.filter((item) => item.value.startsWith(prefix));
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args, ctx) => {
      const trimmed = args.trim();
      const level = trimmed
        ? (trimmed as ThinkingLevel)
        : await ctx.ui.custom<ThinkingLevel | null>((tui, theme, _keybindings, done) => {
            const current = pi.getThinkingLevel();
            const items: SelectItem[] = levels.map((level) => ({
              value: level,
              label: level === current ? `${level} (current)` : level,
            }));

            const container = new Container();
            container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
            container.addChild(new Text(theme.fg("accent", theme.bold("Select reasoning level")), 1, 0));

            const selectList = new SelectList(items, levels.length, {
              selectedPrefix: (s: string) => theme.fg("accent", s),
              selectedText: (s: string) => theme.fg("accent", s),
              description: (s: string) => theme.fg("muted", s),
              scrollInfo: (s: string) => theme.fg("dim", s),
              noMatch: (s: string) => theme.fg("warning", s),
            });
            selectList.setSelectedIndex(Math.max(0, levels.indexOf(current as ThinkingLevel)));
            selectList.onSelect = (item) => done(item.value as ThinkingLevel);
            selectList.onCancel = () => done(null);
            container.addChild(selectList);

            container.addChild(new Text(theme.fg("dim", "↑↓ navigate • enter select • esc cancel"), 1, 0));
            container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

            return {
              render: (width: number) => container.render(width),
              invalidate: () => container.invalidate(),
              handleInput: (data: string) => {
                selectList.handleInput(data);
                tui.requestRender();
              },
            };
          });

      if (!level) return;

      if (!levels.includes(level)) {
        ctx.ui.notify(`Usage: /reasoning ${levels.join("|")}`, "error");
        return;
      }

      pi.setThinkingLevel(level);
      ctx.ui.notify(`Reasoning level set to ${pi.getThinkingLevel()}`, "info");
    },
  };

  pi.registerCommand("reasoning", command);
  pi.registerCommand("thinking", command);
}
