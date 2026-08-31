import {
  Clipboard,
  LaunchType,
  Toast,
  getFrontmostApplication,
  getSelectedText,
  launchCommand,
  showToast,
} from "@raycast/api";
import { createCompletion } from "./client";
import { getProviderConfig, getReasoningEffort } from "./config";
import { ModelNotSelectedError, requireSelectedModel } from "./model-store";

interface RewriteOptions {
  clipboardSuccessTitle: string;
  progressTitle: string;
  successTitle: string;
  systemPrompt: string;
}

interface RewriteInput {
  source: "clipboard" | "selection";
  text: string;
}

export async function runRewrite(options: RewriteOptions): Promise<void> {
  const toast = await showToast({
    style: Toast.Style.Animated,
    title: options.progressTitle,
  });

  try {
    const config = getProviderConfig();
    const reasoningEffort = getReasoningEffort();
    const modelId = await requireSelectedModel(config);
    const sourceApplication = await getFrontmostApplication();
    const input = await readRewriteInput();
    const { leadingWhitespace, content, trailingWhitespace } = splitOuterWhitespace(input.text);

    const rewrittenText = await createCompletion(
      options.systemPrompt,
      content,
      modelId,
      reasoningEffort,
    );
    const replacement = `${leadingWhitespace}${rewrittenText.trim()}${trailingWhitespace}`;

    if (input.source === "clipboard") {
      await Clipboard.copy(replacement);
      toast.style = Toast.Style.Success;
      toast.title = options.clipboardSuccessTitle;
      toast.message = modelId;
      return;
    }

    const currentApplication = await getFrontmostApplication().catch(() => undefined);

    if (!currentApplication || !isSameApplication(sourceApplication, currentApplication)) {
      await Clipboard.copy(replacement);
      toast.style = Toast.Style.Success;
      toast.title = "Result Copied";
      toast.message = `${sourceApplication.name} is no longer frontmost, so nothing was replaced.`;
      return;
    }

    await Clipboard.paste(replacement);
    toast.style = Toast.Style.Success;
    toast.title = options.successTitle;
    toast.message = modelId;
  } catch (error) {
    if (error instanceof ModelNotSelectedError) {
      toast.style = Toast.Style.Failure;
      toast.title = "Select a Model First";
      toast.message = "Opening the model picker...";
      await launchCommand({ name: "select-model", type: LaunchType.UserInitiated });
      return;
    }

    toast.style = Toast.Style.Failure;
    toast.title = "Writing Command Failed";
    toast.message = error instanceof Error ? error.message : String(error);
  }
}

async function readRewriteInput(): Promise<RewriteInput> {
  try {
    const selectedText = await getSelectedText();
    if (selectedText.trim()) {
      return { source: "selection", text: selectedText };
    }
  } catch {
    // Fall back to clipboard text when the frontmost application has no selection.
  }

  const clipboardText = await Clipboard.readText();
  if (!clipboardText?.trim()) {
    throw new Error("Select some text or copy text to the clipboard and try again.");
  }

  return { source: "clipboard", text: clipboardText };
}

function splitOuterWhitespace(value: string): {
  leadingWhitespace: string;
  content: string;
  trailingWhitespace: string;
} {
  const leadingWhitespace = value.match(/^\s*/)?.[0] || "";
  const withoutLeading = value.slice(leadingWhitespace.length);
  const trailingWhitespace = withoutLeading.match(/\s*$/)?.[0] || "";
  const content = withoutLeading.slice(0, withoutLeading.length - trailingWhitespace.length);

  return { leadingWhitespace, content, trailingWhitespace };
}

function isSameApplication(
  left: { bundleId?: string; path: string },
  right: { bundleId?: string; path: string },
): boolean {
  return left.bundleId && right.bundleId
    ? left.bundleId === right.bundleId
    : left.path === right.path;
}
