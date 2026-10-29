import { definePlugin, Field, IconsModule } from 'millennium';
export default definePlugin(() => ({
  icon: <IconsModule.Settings />,
  content: <Field label="Steam Nexus 0.1.0" description="Development preview. Sidebar integration awaits Millennium runtime validation." />,
}));
