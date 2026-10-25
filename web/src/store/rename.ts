import { useSyncExternalStore } from 'react';

// Slot of the player inventory being renamed (right click > Rename), and names waiting for the server.

let renaming: number | null = null;
const pending = new Map<number, { label: string; until: number }>();
const listeners = new Set<() => void>();
let version = 0;

const emit = () => {
  version++;
  listeners.forEach((listener) => listener());
};

export const startRename = (slot: number) => {
  renaming = slot;
  emit();
};

export const stopRename = () => {
  renaming = null;
  emit();
};

export const setPendingLabel = (slot: number, label: string) => {
  pending.set(slot, { label, until: Date.now() + 1500 });
  emit();
  setTimeout(emit, 1600);
};

export const clearPendingLabel = (slot: number) => {
  if (pending.delete(slot)) emit();
};

export const getPendingLabel = (slot: number) => {
  const entry = pending.get(slot);
  if (!entry) return undefined;
  if (entry.until < Date.now()) {
    pending.delete(slot);
    return undefined;
  }
  return entry.label;
};

export const isRenaming = () => renaming !== null;

export const getRenaming = () => renaming;

const subscribe = (listener: () => void) => {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
};

export const useRenameState = () => {
  useSyncExternalStore(subscribe, () => version);
  return renaming;
};
