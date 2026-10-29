import { definePlugin, Field, IconsModule, pluginConfig, subscribePluginConfig } from 'millennium';
import { FeatureRegistry } from './core/lifecycle';
import { driveDefaults, driveSettings } from './core/settings';
import { createDriveIndicatorsFeature } from './features/drive-indicators';

export default definePlugin(async () => {
  const registry = new FeatureRegistry([
    createDriveIndicatorsFeature(() => backend.getInstallationsJson()),
  ]);
  const report = (error: unknown): void => console.error('[Steam Nexus]', error);
  const unsubscribe = subscribePluginConfig((key, value) => {
    if (key === driveSettings.enabled) registry.setEnabled('drive-indicators', value !== false).catch(report);
  });
  try {
    const enabled = await pluginConfig.get<boolean | undefined>(driveSettings.enabled);
    await registry.setEnabled('drive-indicators', enabled ?? driveDefaults.enabled);
  } catch (error) {
    report(error);
  }
  return {
    icon: <IconsModule.Settings />,
    content: <Field label="Steam Nexus 0.1.0" description="Storage foundation preview. Sidebar indicators and settings controls await Millennium runtime validation." />,
    onDismount() {
      unsubscribe();
      registry.dispose().catch(report);
    },
  };
});
