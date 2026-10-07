import { createContext, useContext } from 'react';

import { useBackend } from '../../backend';

type ModuleBackend = {
  data: unknown;
  act: (action: string, params?: Record<string, unknown>) => void;
};

export const ModuleBackendContext = createContext<ModuleBackend | null>(null);

export function useModuleBackend<TData extends Record<string, any>>() {
  const backend = useBackend<TData>();
  const override = useContext(ModuleBackendContext);
  if (!override) {
    return backend;
  }
  return { ...backend, data: override.data as TData, act: override.act };
}
