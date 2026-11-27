import { atom, useAtom } from 'jotai';

const compactAtom = atom(false);

export const useCompact = () => useAtom(compactAtom);
