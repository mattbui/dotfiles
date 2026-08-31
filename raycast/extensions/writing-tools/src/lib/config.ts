import { getPreferenceValues } from "@raycast/api";

export const DEFAULT_API_BASE_URL = "https://api.openai.com/v1";

interface ExtensionPreferences {
  apiKey?: string;
  apiBaseUrl?: string;
}

export type ReasoningEffort = "none" | "minimal" | "low" | "medium" | "high" | "xhigh";

interface WritingCommandPreferences extends ExtensionPreferences {
  reasoningEffort?: ReasoningEffort | "provider-default";
}

export interface ProviderConfig {
  apiKey?: string;
  baseUrl: string;
}

export class ConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConfigurationError";
  }
}

export function getProviderConfig(): ProviderConfig {
  const preferences = getPreferenceValues<ExtensionPreferences>();

  return {
    apiKey: preferences.apiKey?.trim() || undefined,
    baseUrl: normalizeApiBaseUrl(preferences.apiBaseUrl),
  };
}

export function getReasoningEffort(): ReasoningEffort | undefined {
  const preferences = getPreferenceValues<WritingCommandPreferences>();

  return preferences.reasoningEffort && preferences.reasoningEffort !== "provider-default"
    ? preferences.reasoningEffort
    : undefined;
}

export function normalizeApiBaseUrl(value?: string): string {
  const configuredValue = value?.trim() || DEFAULT_API_BASE_URL;
  let url: URL;

  try {
    url = new URL(configuredValue);
  } catch {
    throw new ConfigurationError("API Base URL must be a valid URL.");
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new ConfigurationError("API Base URL must use HTTP or HTTPS.");
  }

  if (url.username || url.password) {
    throw new ConfigurationError("Put credentials in API Key, not in the API Base URL.");
  }

  if (url.search || url.hash) {
    throw new ConfigurationError("API Base URL cannot contain a query string or fragment.");
  }

  url.pathname = url.pathname.replace(/\/+$/, "");
  url.pathname = url.pathname.replace(/\/chat\/completions$/, "");

  return url.toString().replace(/\/$/, "");
}

export function validateProviderCredentials(config: ProviderConfig): void {
  if (config.baseUrl === DEFAULT_API_BASE_URL && !config.apiKey) {
    throw new ConfigurationError("Set an API key before using the OpenAI API.");
  }
}
