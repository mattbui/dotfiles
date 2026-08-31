import {
  ProviderConfig,
  ReasoningEffort,
  getProviderConfig,
  validateProviderCredentials,
} from "./config";

const COMPLETION_TIMEOUT_MS = 60_000;
const MODEL_LIST_TIMEOUT_MS = 15_000;

interface ChatCompletionResponse {
  choices?: Array<{
    message?: {
      content?: string | Array<{ type?: string; text?: string }> | null;
    };
  }>;
}

interface ModelsResponse {
  data?: Array<{
    id?: string;
    owned_by?: string;
  }>;
}

export interface ProviderModel {
  id: string;
  ownedBy?: string;
}

export class ProviderApiError extends Error {
  readonly status?: number;

  constructor(message: string, status?: number) {
    super(message);
    this.name = "ProviderApiError";
    this.status = status;
  }
}

export async function createCompletion(
  systemPrompt: string,
  sourceText: string,
  modelId: string,
  reasoningEffort?: ReasoningEffort,
): Promise<string> {
  const requestBody = {
    model: modelId,
    ...(reasoningEffort ? { reasoning_effort: reasoningEffort } : {}),
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: sourceText },
    ],
  };

  const response = await providerRequest<ChatCompletionResponse>(
    "chat/completions",
    {
      method: "POST",
      body: JSON.stringify(requestBody),
    },
    COMPLETION_TIMEOUT_MS,
  );

  const content = response.choices?.[0]?.message?.content;
  const text = extractTextContent(content);
  if (!text.trim()) {
    throw new ProviderApiError("The provider returned an empty response.");
  }
  return text;
}

export async function listModels(): Promise<ProviderModel[]> {
  const response = await providerRequest<ModelsResponse>(
    "models",
    { method: "GET" },
    MODEL_LIST_TIMEOUT_MS,
  );

  if (!Array.isArray(response.data)) {
    throw new ProviderApiError("The provider returned an invalid model list.");
  }

  const models = response.data
    .filter((model): model is { id: string; owned_by?: string } => Boolean(model.id?.trim()))
    .map((model) => ({ id: model.id.trim(), ownedBy: model.owned_by?.trim() || undefined }));

  return Array.from(new Map(models.map((model) => [model.id, model])).values()).sort(
    (left, right) => left.id.localeCompare(right.id),
  );
}

async function providerRequest<T>(path: string, init: RequestInit, timeoutMs: number): Promise<T> {
  const config = getProviderConfig();
  validateProviderCredentials(config);

  const controller = new AbortController();
  let didTimeout = false;
  const timeout = setTimeout(() => {
    didTimeout = true;
    controller.abort();
  }, timeoutMs);

  try {
    const response = await fetch(`${config.baseUrl}/${path}`, {
      ...init,
      headers: buildHeaders(config, init.method),
      signal: controller.signal,
    });
    const rawBody = await response.text();
    const body = parseJson(rawBody);

    if (!response.ok) {
      throw new ProviderApiError(getProviderError(body, rawBody, response.status), response.status);
    }

    if (!body || typeof body !== "object") {
      throw new ProviderApiError("The provider returned an invalid JSON response.");
    }

    return body as T;
  } catch (error) {
    if (didTimeout) {
      throw new ProviderApiError(
        `The provider did not respond within ${timeoutMs / 1000} seconds.`,
      );
    }
    if (error instanceof ProviderApiError) {
      throw error;
    }
    throw new ProviderApiError(error instanceof Error ? error.message : String(error));
  } finally {
    clearTimeout(timeout);
  }
}

function buildHeaders(config: ProviderConfig, method?: string): Record<string, string> {
  const headers: Record<string, string> = { Accept: "application/json" };
  if (method !== "GET") {
    headers["Content-Type"] = "application/json";
  }
  if (config.apiKey) {
    headers.Authorization = `Bearer ${config.apiKey}`;
  }
  return headers;
}

function parseJson(value: string): unknown {
  if (!value) {
    return undefined;
  }
  try {
    return JSON.parse(value) as unknown;
  } catch {
    return undefined;
  }
}

function getProviderError(body: unknown, rawBody: string, status: number): string {
  if (body && typeof body === "object" && "error" in body) {
    const error = (body as { error?: unknown }).error;
    if (typeof error === "string") {
      return truncate(error);
    }
    if (error && typeof error === "object" && "message" in error) {
      const message = (error as { message?: unknown }).message;
      if (typeof message === "string") {
        return truncate(message);
      }
    }
  }

  return rawBody.trim() ? truncate(rawBody.trim()) : `Provider request failed with HTTP ${status}.`;
}

function extractTextContent(
  content: string | Array<{ type?: string; text?: string }> | null | undefined,
): string {
  if (typeof content === "string") {
    return content;
  }
  if (Array.isArray(content)) {
    return content.map((part) => part.text || "").join("");
  }
  return "";
}

function truncate(value: string): string {
  const compact = value.replace(/\s+/g, " ");
  return compact.length > 300 ? `${compact.slice(0, 297)}...` : compact;
}
