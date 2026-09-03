import { LaunchProps, Toast, showToast } from "@raycast/api";
import { buildEditTextPrompt } from "./lib/prompts";
import { runRewrite } from "./lib/rewrite";

export default async function Command(
  props: LaunchProps<{ arguments: Arguments.EditTextWithPrompt }>,
) {
  const prompt = props.arguments.prompt.trim();
  if (!prompt) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Enter Editing Instructions",
      message: "Describe what you want to change, such as making the text shorter.",
    });
    return;
  }

  await runRewrite({
    clipboardSuccessTitle: "Edited Text Copied",
    progressTitle: "Editing Text...",
    successTitle: "Text Edited",
    systemPrompt: buildEditTextPrompt(prompt),
  });
}
