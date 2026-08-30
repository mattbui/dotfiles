import { LocalStorage } from "@raycast/api";
import { getProviderConfig, ProviderConfig } from "./config";

const SELECTED_MODEL_KEY = "selected-model-v1";

interface StoredModel {
  baseUrl: string;
  modelId: string;
}

export class ModelNotSelectedError extends Error {
  constructor() {
    super("Select a model before running a writing command.");
    this.name = "ModelNotSelectedError";
  }
}

export async function getSelectedModel(config = getProviderConfig()): Promise<string | undefined> {
  const value = await LocalStorage.getItem<string>(SELECTED_MODEL_KEY);
  if (!value) {
    return undefined;
  }

  try {
    const stored = JSON.parse(value) as StoredModel;
    if (stored.baseUrl !== config.baseUrl || !stored.modelId?.trim()) {
      return undefined;
    }
    return stored.modelId.trim();
  } catch {
    return undefined;
  }
}

export async function requireSelectedModel(config = getProviderConfig()): Promise<string> {
  const modelId = await getSelectedModel(config);
  if (!modelId) {
    throw new ModelNotSelectedError();
  }
  return modelId;
}

export async function setSelectedModel(
  modelId: string,
  config: ProviderConfig = getProviderConfig(),
): Promise<void> {
  const normalizedModelId = modelId.trim();
  if (!normalizedModelId) {
    throw new Error("Model ID cannot be empty.");
  }

  const value: StoredModel = {
    baseUrl: config.baseUrl,
    modelId: normalizedModelId,
  };
  await LocalStorage.setItem(SELECTED_MODEL_KEY, JSON.stringify(value));
}
