import type { NexusFeature } from '../../core/lifecycle';

export interface InstalledGame {
  appId: string;
  installPath: string;
  drive: string;
}

export interface InstallationSnapshot {
  available: boolean;
  disabled?: boolean;
  error?: string;
  games: Record<string, InstalledGame>;
  skippedLibraries?: number;
  skippedManifests?: number;
  metadataWarning?: boolean;
}

export function createDriveIndicatorsFeature(load: () => Promise<string>): NexusFeature {
  let snapshot: InstallationSnapshot | undefined;
  return {
    id: 'drive-indicators',
    name: 'Drive Indicators',
    description: 'Library installation drive indicators; sidebar adapter awaiting runtime validation.',
    async enable() {
      const parsed = JSON.parse(await load()) as InstallationSnapshot;
      if (typeof parsed.available !== 'boolean' || !parsed.games || typeof parsed.games !== 'object') {
        throw new Error('Invalid installation snapshot');
      }
      snapshot = parsed;
      if (!snapshot.available && !snapshot.disabled) throw new Error(snapshot.error ?? 'Storage unavailable');
    },
    disable() {
      snapshot = undefined;
    },
  };
}
