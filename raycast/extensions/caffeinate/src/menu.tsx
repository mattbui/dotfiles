import { useEffect, useState } from "react";
import {
  Color,
  Icon,
  openExtensionPreferences,
  MenuBarExtra,
} from "@raycast/api";
import { labels, policies } from "./model";
import type { Mode, State } from "./model";
import type { Request } from "./engine";
import { perform, refresh } from "./service";

export function ModeMenu({ mode }: { mode: Mode }) {
  const [state, setState] = useState<State>();
  const [error, setError] = useState<string>();
  const [loading, setLoading] = useState(true);
  async function run(request: Request) {
    setLoading(true);
    setError(undefined);
    try {
      const result = await perform(request);
      setState(result.state);
      if (result.state.modes[mode].reason?.startsWith("Cannot read")) {
        setError(result.state.modes[mode].reason);
      }
      // This component renders its own new state. Only changed siblings need another launch.
      await refresh(result.changed.filter((item) => item !== mode));
    } catch (error) {
      setError(error instanceof Error ? error.message : String(error));
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => {
    void run({ kind: "poll" });
  }, []);
  const item = state?.modes[mode];
  if (!loading && !error && !item?.process) return null;
  return (
    <MenuBarExtra
      icon={
        error
          ? Icon.ExclamationMark
          : {
              source: mode === "display" ? "display-glint.svg" : `${mode}.svg`,
              tintColor: Color.PrimaryText,
            }
      }
      isLoading={loading}
      tooltip={
        error
          ? `${labels[mode]}: ${error}`
          : `${labels[mode]} sleep prevention active`
      }
    >
      <MenuBarExtra.Item title={`${labels[mode]} sleep prevention`} />
      {error && <MenuBarExtra.Item title={error} />}
      {item?.process && (
        <MenuBarExtra.Item title={`Active since ${item.process.started}`} />
      )}
      <MenuBarExtra.Item
        title="Turn Off"
        onAction={() => run({ kind: "off", mode })}
      />
      <MenuBarExtra.Item
        title="Turn Off All"
        onAction={() => run({ kind: "off-all" })}
      />
      <MenuBarExtra.Separator />
      {item && <MenuBarExtra.Item title={policies[item.policy]} />}
      <MenuBarExtra.Item
        title="Settings"
        icon={Icon.Gear}
        onAction={openExtensionPreferences}
      />
      <MenuBarExtra.Item
        title="Refresh"
        onAction={() => run({ kind: "poll" })}
      />
    </MenuBarExtra>
  );
}
