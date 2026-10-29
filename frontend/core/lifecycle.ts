export interface NexusFeature {
  id: string;
  name: string;
  description: string;
  enable(): void | Promise<void>;
  disable(): void | Promise<void>;
}

export class FeatureRegistry {
  private readonly active = new Set<string>();
  private queue: Promise<void> = Promise.resolve();
  private stopped = false;

  constructor(private readonly features: NexusFeature[]) {
    if (new Set(features.map(feature => feature.id)).size !== features.length) {
      throw new Error('Duplicate feature ID');
    }
  }

  setEnabled(id: string, enabled: boolean): Promise<void> {
    if (this.stopped) return Promise.reject(new Error('Registry stopped'));
    const task = this.queue.then(async () => {
      const feature = this.features.find(candidate => candidate.id === id);
      if (!feature) throw new Error(`Unknown feature: ${id}`);
      if (this.active.has(id) === enabled) return;
      if (enabled) {
        try {
          await feature.enable();
          this.active.add(id);
        } catch (error) {
          await feature.disable();
          throw error;
        }
      } else {
        await feature.disable();
        this.active.delete(id);
      }
    });
    this.queue = task.catch((): void => {});
    return task;
  }

  dispose(): Promise<void> {
    this.stopped = true;
    const task = this.queue.then(async () => {
      const errors: unknown[] = [];
      for (const feature of this.features) {
        if (!this.active.has(feature.id)) continue;
        try {
          await feature.disable();
          this.active.delete(feature.id);
        } catch (error) {
          errors.push(error);
        }
      }
      if (errors.length) throw new Error(`Failed to disable ${errors.length} feature(s)`);
    });
    this.queue = task.catch((): void => {});
    return task;
  }
}

