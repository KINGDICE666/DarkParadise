import { createContext, useContext } from 'react';

import type { ServerData } from './types';

export const ServerPrefs = createContext<ServerData | undefined>(undefined);

export function useServerPrefs() {
  return useContext(ServerPrefs);
}
