import { useSyncExternalStore } from 'react';

// Settings sent by the game with the `init` message (config.lua).

export interface ClothingSlotConfig {
  key: string;
  side: 'left' | 'right';
  icon: string;
  label: string;
}

// Hanger slot (Config.Clothing.Hanger): null when it is disabled.
export interface HangerConfig {
  side: 'left' | 'right';
  label: string;
  outfitItem: string;
  hangerItem: string;
}

export interface Features {
  preview: boolean;
  clothing: boolean;
  rename: boolean;
  renameMax: number;
}

export interface Settings {
  theme: Record<string, unknown>;
  clothing: ClothingSlotConfig[];
  hanger: HangerConfig | null;
  features: Features;
}

let settings: Settings = {
  theme: {},
  clothing: [],
  hanger: null,
  features: { preview: false, clothing: false, rename: false, renameMax: 32 },
};

const listeners = new Set<() => void>();

export const setSettings = (next: Partial<Settings>) => {
  settings = { ...settings, ...next, features: { ...settings.features, ...(next.features || {}) } };
  listeners.forEach((listener) => listener());
};

export const getSettings = () => settings;

const subscribe = (listener: () => void) => {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
};

export const useSettings = () => useSyncExternalStore(subscribe, getSettings);
