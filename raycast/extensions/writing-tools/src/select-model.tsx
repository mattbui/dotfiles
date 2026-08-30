import {
  Action,
  ActionPanel,
  Form,
  Icon,
  Keyboard,
  List,
  openExtensionPreferences,
  showHUD,
} from "@raycast/api";
import { useCallback, useEffect, useMemo, useState } from "react";
import { ProviderModel, listModels } from "./lib/client";
import { getProviderConfig } from "./lib/config";
import { getSelectedModel, setSelectedModel } from "./lib/model-store";

interface ModelPickerState {
  baseUrl?: string;
  currentModel?: string;
  error?: string;
  isLoading: boolean;
  models: ProviderModel[];
}

interface CustomModelFormProps {
  currentModel?: string;
}

export default function Command() {
  const [revision, setRevision] = useState(0);
  const [state, setState] = useState<ModelPickerState>({ isLoading: true, models: [] });

  const refresh = useCallback(async () => {
    setState((current) => ({ ...current, error: undefined, isLoading: true }));
    try {
      const config = getProviderConfig();
      const [models, currentModel] = await Promise.all([listModels(), getSelectedModel(config)]);
      setState({
        baseUrl: config.baseUrl,
        currentModel,
        isLoading: false,
        models,
      });
    } catch (error) {
      let currentModel: string | undefined;
      let baseUrl: string | undefined;
      try {
        const config = getProviderConfig();
        baseUrl = config.baseUrl;
        currentModel = await getSelectedModel(config);
      } catch {
        // Keep the original configuration error below.
      }
      setState({
        baseUrl,
        currentModel,
        error: error instanceof Error ? error.message : String(error),
        isLoading: false,
        models: [],
      });
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh, revision]);

  const models = useMemo(() => {
    if (!state.currentModel || state.models.some((model) => model.id === state.currentModel)) {
      return state.models;
    }
    return [{ id: state.currentModel }, ...state.models];
  }, [state.currentModel, state.models]);

  async function chooseModel(modelId: string) {
    await setSelectedModel(modelId);
    await showHUD(`✓ Model selected: ${modelId}`);
  }

  const sharedActions = (
    <>
      <Action.Push
        title="Enter Custom Model ID"
        icon={Icon.Pencil}
        target={<CustomModelForm currentModel={state.currentModel} />}
      />
      <Action
        title="Refresh Models"
        icon={Icon.ArrowClockwise}
        shortcut={Keyboard.Shortcut.Common.Refresh}
        onAction={() => setRevision((value) => value + 1)}
      />
      <Action
        title="Open Extension Preferences"
        icon={Icon.Gear}
        onAction={openExtensionPreferences}
      />
    </>
  );

  return (
    <List
      isLoading={state.isLoading}
      navigationTitle="Select Model"
      searchBarPlaceholder="Search available models"
    >
      {!state.isLoading && models.length === 0 ? (
        <List.EmptyView
          icon={Icon.MagnifyingGlass}
          title={state.error ? "Could Not Load Models" : "No Models Found"}
          description={state.error || "The provider returned an empty model list."}
          actions={<ActionPanel>{sharedActions}</ActionPanel>}
        />
      ) : null}

      <List.Section title={state.baseUrl ? `Provider: ${state.baseUrl}` : "Models"}>
        {state.error && models.length > 0 ? (
          <List.Item
            icon="⚠️"
            title="Could Not Refresh Models"
            subtitle={state.error}
            actions={<ActionPanel>{sharedActions}</ActionPanel>}
          />
        ) : null}
        {models.map((model) => {
          const isSelected = model.id === state.currentModel;
          return (
            <List.Item
              key={model.id}
              icon={isSelected ? Icon.CheckCircle : Icon.Circle}
              title={model.id}
              subtitle={model.ownedBy}
              accessories={isSelected ? [{ text: "Selected" }] : undefined}
              actions={
                <ActionPanel>
                  <Action title="Select Model" onAction={() => chooseModel(model.id)} />
                  {sharedActions}
                </ActionPanel>
              }
            />
          );
        })}
      </List.Section>
    </List>
  );
}

function CustomModelForm(props: CustomModelFormProps) {
  const [error, setError] = useState<string>();

  async function save(values: { modelId: string }) {
    try {
      const modelId = values.modelId.trim();
      if (!modelId) {
        setError("Enter a model ID.");
        return;
      }
      await setSelectedModel(modelId);
      await showHUD(`✓ Model selected: ${modelId}`);
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : String(saveError));
    }
  }

  return (
    <Form
      navigationTitle="Enter Custom Model ID"
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Select Model" onSubmit={save} />
        </ActionPanel>
      }
    >
      <Form.TextField
        id="modelId"
        title="Model ID"
        placeholder="gpt-4o-mini"
        defaultValue={props.currentModel}
        error={error}
        onChange={() => setError(undefined)}
      />
      <Form.Description text="Use the exact model ID accepted by the configured provider." />
    </Form>
  );
}
