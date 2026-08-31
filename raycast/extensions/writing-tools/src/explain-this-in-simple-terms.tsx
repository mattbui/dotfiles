import {
  Action,
  ActionPanel,
  Clipboard,
  Detail,
  Icon,
  Keyboard,
  LaunchType,
  getSelectedText,
  launchCommand,
  openExtensionPreferences,
} from "@raycast/api";
import { useEffect, useState } from "react";
import { createCompletion } from "./lib/client";
import { getProviderConfig, getReasoningEffort } from "./lib/config";
import { EXPLAIN_IN_SIMPLE_TERMS_PROMPT } from "./lib/prompts";
import { requireSelectedModel } from "./lib/model-store";

interface ExplanationState {
  error?: string;
  isLoading: boolean;
  text?: string;
}

export default function Command() {
  const [revision, setRevision] = useState(0);
  const [state, setState] = useState<ExplanationState>({ isLoading: true });

  useEffect(() => {
    let cancelled = false;

    async function explainSelectedText() {
      setState({ isLoading: true });
      try {
        const config = getProviderConfig();
        const reasoningEffort = getReasoningEffort();
        const modelId = await requireSelectedModel(config);
        const sourceText = await readSourceText();

        const text = await createCompletion(
          EXPLAIN_IN_SIMPLE_TERMS_PROMPT,
          sourceText,
          modelId,
          reasoningEffort,
        );
        if (!cancelled) {
          setState({ isLoading: false, text: text.trim() });
        }
      } catch (error) {
        if (!cancelled) {
          setState({
            error: error instanceof Error ? error.message : String(error),
            isLoading: false,
          });
        }
      }
    }

    void explainSelectedText();
    return () => {
      cancelled = true;
    };
  }, [revision]);

  const markdown = state.error
    ? `# Unable to Explain Text\n\n${escapeMarkdown(state.error)}`
    : state.text || "";

  return (
    <Detail
      isLoading={state.isLoading}
      markdown={markdown}
      navigationTitle="Explain This in Simple Terms"
      actions={
        <ActionPanel>
          {state.text ? (
            <>
              <Action.CopyToClipboard title="Copy Explanation" content={state.text} />
              <Action.Paste title="Paste Explanation" content={state.text} />
            </>
          ) : null}
          <Action
            title="Retry"
            icon={Icon.ArrowClockwise}
            shortcut={Keyboard.Shortcut.Common.Refresh}
            onAction={() => setRevision((value) => value + 1)}
          />
          <Action
            title="Select Model"
            icon={Icon.Gear}
            onAction={() => launchCommand({ name: "select-model", type: LaunchType.UserInitiated })}
          />
          <Action
            title="Open Extension Preferences"
            icon={Icon.Gear}
            onAction={openExtensionPreferences}
          />
        </ActionPanel>
      }
    />
  );
}

async function readSourceText(): Promise<string> {
  try {
    const selectedText = await getSelectedText();
    if (selectedText.trim()) {
      return selectedText;
    }
  } catch {
    // Fall back to clipboard text when the frontmost application has no selection.
  }

  const clipboardText = await Clipboard.readText();
  if (!clipboardText?.trim()) {
    throw new Error("Select some text or copy text to the clipboard and try again.");
  }
  return clipboardText;
}

function escapeMarkdown(value: string): string {
  return value.replace(/([\\`*_{}[\]()<>#+.!|-])/g, "\\$1");
}
