import { FIX_SPELLING_AND_GRAMMAR_PROMPT } from "./lib/prompts";
import { runRewrite } from "./lib/rewrite";

export default async function Command() {
  await runRewrite({
    clipboardSuccessTitle: "Corrected Text Copied",
    progressTitle: "Fixing Spelling and Grammar...",
    successTitle: "Spelling and Grammar Fixed",
    systemPrompt: FIX_SPELLING_AND_GRAMMAR_PROMPT,
  });
}
