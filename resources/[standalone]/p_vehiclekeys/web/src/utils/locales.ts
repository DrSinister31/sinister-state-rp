import { useSyncExternalStore } from 'react';
import { fetchNui } from './fetchNui';
import { isEnvBrowser } from './misc';

type LocaleDict = Record<string, string>;

let store: LocaleDict = {};
const listeners = new Set<() => void>();

const subscribe = (fn: () => void) => {
    listeners.add(fn);
    return () => listeners.delete(fn);
};

const getSnapshot = () => store;

const notify = () => {
    listeners.forEach((fn) => fn());
};

export const setLocales = (data: LocaleDict) => {
    store = data ?? {};
    notify();
};

const format = (template: string, args: unknown[]): string => {
    if (args.length === 0) return template;
    let i = 0;
    return template.replace(/%s/g, () => {
        const v = args[i++];
        return v === undefined || v === null ? '' : String(v);
    });
};

export const t = (key: string, ...args: unknown[]): string => {
    const value = store[key];
    if (value === undefined) return key;
    return format(value, args);
};

export const useT = () => {
    useSyncExternalStore(subscribe, getSnapshot, getSnapshot);
    return t;
};

let loadPromise: Promise<void> | null = null;

export const loadLocales = (): Promise<void> => {
    if (loadPromise) return loadPromise;
    loadPromise = (async () => {
        if (isEnvBrowser()) return;
        try {
            const data = await fetchNui<LocaleDict>('getLocales', {}, {});
            setLocales(data || {});
        } catch (err) {
            console.warn('[locales] failed to load:', err);
        }
    })();
    return loadPromise;
};
