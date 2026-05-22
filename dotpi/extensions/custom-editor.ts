import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function stripAnsi(text: string): string {
	return text.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
}

function padToVisibleWidth(text: string, width: number): string {
	return text + " ".repeat(Math.max(0, width - visibleWidth(text)));
}

class CustomizedEditor extends CustomEditor {
	private promptMarkerColor: (text: string) => string;
	private editorBg: (text: string) => string;

	constructor(
		tui: any,
		theme: any,
		keybindings: any,
		promptMarkerColor: (text: string) => string,
		editorBg: (text: string) => string,
	) {
		super(tui, theme, keybindings);
		this.promptMarkerColor = promptMarkerColor;
		this.editorBg = editorBg;
	}
	setPaddingX(padding: number): void {
		// Keep enough left padding to draw the prompt marker without changing line width.
		super.setPaddingX(Math.max(2, padding));
	}

	render(width: number): string[] {
		const lines = super.render(width);

		// Remove the editor's top and bottom border lines while keeping content
		// and autocomplete lines intact.
		const withoutTopBorder = lines.slice(1);
		const bottomBorderIndex = withoutTopBorder.findIndex((line) => stripAnsi(line).startsWith("─"));
		if (bottomBorderIndex !== -1) {
			withoutTopBorder.splice(bottomBorderIndex, 1);
		}

		const firstContentLine = withoutTopBorder.findIndex((line) => line.startsWith("  "));
		if (firstContentLine !== -1) {
			withoutTopBorder[firstContentLine] = ` ${this.promptMarkerColor("›")} ${withoutTopBorder[firstContentLine].slice(2)}`;
		}
		const editorLines = ["", ...withoutTopBorder, ""];
		return editorLines.map((line) =>
			// The editor cursor contains an ANSI reset (\x1b[0m). If we wrap the
			// whole line once, that reset clears the background for the rest of the
			// line. Apply the background to each reset-delimited segment instead.
			truncateToWidth(
				padToVisibleWidth(line, width)
					.split("\x1b[0m")
					.map((segment) => this.editorBg(segment))
					.join("\x1b[0m"),
				width,
				"",
			),
		);
	}

	handleInput(data: string): void {
		const text = this.getText();

		// If autocomplete/slash-command menu is open, Enter should first accept
		// the highlighted completion, then submit the filled slash command.
		if (matchesKey(data, "enter") && this.isShowingAutocomplete()) {
			super.handleInput("\t");
			if (this.getText().trimStart().startsWith("/")) {
				this.submitCurrentText();
			}
			return;
		}

		// Plain Enter submits slash commands, otherwise inserts a newline.
		if (matchesKey(data, "enter")) {
			if (text.trimStart().startsWith("/")) {
				this.submitCurrentText();
			} else {
				this.insertTextAtCursor("\n");
			}
			return;
		}

		// Cmd+Enter in your Alacritty config sends CSI-u Alt+Enter.
		// Submit directly instead of passing through pi's follow-up keybinding.
		if (matchesKey(data, "alt+enter")) {
			this.submitCurrentText();
			return;
		}

		super.handleInput(data);
	}

	private submitCurrentText(): void {
		const text = this.getExpandedText().trim();
		if (!text) return;

		this.setText("");
		this.onSubmit?.(text);
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, keybindings) =>
			new CustomizedEditor(
				tui,
				theme,
				keybindings,
				(text: string) => ctx.ui.theme.fg("accent", text),
				(text: string) => ctx.ui.theme.bg("userMessageBg", text),
			),
		);
	});
}
