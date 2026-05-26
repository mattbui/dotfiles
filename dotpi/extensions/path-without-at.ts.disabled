import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { AutocompleteProvider } from "@earendil-works/pi-tui";

// Keep using @ as the trigger for Pi's built-in fuzzy file picker, but remove
// the @ from the inserted path after a completion is accepted.
//
// Leaving @ in the prompt can confuse some models: they may treat it as part of
// the literal filename and then look for/read/edit the wrong path. Plain paths
// are also accepted by Pi's tools, so dropping the marker after selection keeps
// the prompt less ambiguous.

function stripCompletionAtPrefix(value: string): string {
  if (value.startsWith('@"')) return value.slice(1);
  if (value.startsWith("@")) return value.slice(1);
  return value;
}

function createAtPathCompletionWithoutAtProvider(current: AutocompleteProvider): AutocompleteProvider {
  return {
    getSuggestions(lines, cursorLine, cursorCol, options) {
      return current.getSuggestions(lines, cursorLine, cursorCol, options);
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      if (!prefix.startsWith("@")) {
        return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
      }

      const currentLine = lines[cursorLine] ?? "";
      const beforePrefix = currentLine.slice(0, cursorCol - prefix.length);
      const afterCursor = currentLine.slice(cursorCol);
      const value = stripCompletionAtPrefix(item.value);
      const isDirectory = item.label.endsWith("/");
      const suffix = isDirectory ? "" : " ";
      const isQuotedPrefix = prefix.startsWith('@"');
      const hasTrailingQuoteInItem = value.endsWith('"');
      const adjustedAfterCursor = isQuotedPrefix && hasTrailingQuoteInItem && afterCursor.startsWith('"')
        ? afterCursor.slice(1)
        : afterCursor;

      const newLines = [...lines];
      newLines[cursorLine] = beforePrefix + value + suffix + adjustedAfterCursor;

      // For quoted directories, keep the cursor inside the quote so another
      // completion can continue from that directory path.
      const cursorOffset = isDirectory && hasTrailingQuoteInItem ? value.length - 1 : value.length;
      return {
        lines: newLines,
        cursorLine,
        cursorCol: beforePrefix.length + cursorOffset + suffix.length,
      };
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
    },
  };
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.addAutocompleteProvider(createAtPathCompletionWithoutAtProvider);
  });
}
