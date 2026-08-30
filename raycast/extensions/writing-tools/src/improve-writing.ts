import { IMPROVE_WRITING_PROMPT } from "./lib/prompts";
import { runRewrite } from "./lib/rewrite";

export default async function Command() {
  await runRewrite({
    clipboardSuccessTitle: "Improved Text Copied",
    progressTitle: "Improving Writing...",
    successTitle: "Writing Improved",
    systemPrompt: IMPROVE_WRITING_PROMPT,
  });
}
