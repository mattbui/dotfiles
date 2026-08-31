# Writing Tools

A local Raycast extension that recreates Raycast's selected-text writing commands with a custom
OpenAI-compatible API.

## Commands

- **Fix Spelling and Grammar** corrects selected text and replaces it in place. With no selection,
  it reads from the clipboard and copies the corrected result back to the clipboard.
- **Improve Writing** improves selected text and replaces it in place. With no selection, it reads
  from the clipboard and copies the improved result back to the clipboard.
- **Explain This in Simple Terms** displays a concise explanation in Raycast, using clipboard text
  when no text is selected.
- **Select Model** loads a searchable model picker from the configured provider.

The writing prompts follow the behavior of Raycast's published editable prompts:
<https://ray.so/prompts/raycast>

## Requirements

- macOS with [Raycast](https://www.raycast.com/) installed
- Node.js and npm

## Install Locally

From the root of this dotfiles repository, install the extension's dependencies:

```sh
cd raycast/extensions/writing-tools
npm install
```

Then start Raycast's development command:

```sh
npm run dev
```

Raycast imports the local extension and makes its commands available in the main Raycast search.
Keep this process running while changing the extension so Raycast automatically rebuilds it. Press
`Ctrl-C` when you no longer need the development watcher; the imported extension remains available
in Raycast.

To build the extension once without starting the watcher, run:

```sh
npm run build
```

## Configure

1. Open **Raycast Settings**.
2. Select **Extensions**, then find **Writing Tools**.
3. Configure the extension preferences:
   - **API Key**: the provider's bearer token; optional for keyless local servers.
   - **API Base URL**: an OpenAI-compatible base URL; blank uses
     `https://api.openai.com/v1`.
4. Select each writing command in the **Writing Tools** extension page and configure its
   **Reasoning Effort** separately. It defaults to **Minimal**; choose **Provider Default** to omit
   the `reasoning_effort` parameter.
5. Open Raycast and run **Select Model**. Choose a model returned by the provider. If the provider
   does not implement `GET /models`, use **Enter Custom Model ID** from the action panel.
6. Optionally assign hotkeys to the writing commands from the **Writing Tools** extension page in
   Raycast Settings.

## Run

Select text in any application, open Raycast, and run one of these commands:

- **Fix Spelling and Grammar**
- **Improve Writing**
- **Explain This in Simple Terms**

Fix and Improve replace the selection after the provider responds and show a HUD confirming the
result. If there is no selected text, all three commands use text from the clipboard; Fix and
Improve copy their result back to the clipboard, while Explain displays its result in Raycast.

On first use, macOS or Raycast may ask for permission to read or replace selected text. Grant the
requested permission for selection-based commands to work. Clipboard fallback remains available
when an application does not expose its selection to Raycast.

## Provider Contract

The extension uses these OpenAI-compatible endpoints:

- `GET {baseURL}/models`
- `POST {baseURL}/chat/completions`

Writing requests include the command's configured `reasoning_effort` unless **Provider Default**
is selected. Supported effort values vary by model and provider.

The base URL should include any required prefix such as `/v1`, but should not include
`/chat/completions`. Native Anthropic and Gemini endpoints are not supported without an
OpenAI-compatible gateway.

## Behavior and Limitations

- Fix and Improve prefer selected text. With no selection, they read text from the clipboard and
  copy the result back instead of pasting it into the frontmost application.
- Outer whitespace, line breaks, URLs, emojis, and text formatting are preserved as far as the
  selected plain text and model allow.
- If the frontmost application changes while a request is running, the result is copied instead of
  pasted to avoid replacing text in the wrong application.
- Rich-text formatting cannot be preserved as reliably as Raycast's built-in Quick Fix.
- Selected text is sent to the configured API provider.
