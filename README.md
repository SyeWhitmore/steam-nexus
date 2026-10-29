# Steam Nexus 0.1.0

Steam Nexus extends the Windows Steam desktop client with independent, configurable features using Millennium. This development preview establishes the foundation for Library drive indicators. **Sidebar indicators are not implemented yet.** Work stopped at the requested runtime boundary because no Millennium installation was found locally.

## Implemented

- Official Millennium template build, Lua backend and TypeScript/React frontend.
- Feature registry with serialized enable/disable operations and cleanup on plugin dismount.
- Read-only discovery through Millennium's Steam path, modern and legacy library folder entries, and installed app manifests.
- AppID-to-installation-path/drive mapping, malformed metadata handling, inaccessible library handling, session caching and explicit refresh RPC.
- Drive Indicators registered as the first feature; currently loads metadata only.
- Namespaced configuration defaults using Millennium configuration APIs. No custom persistence, database, telemetry or external game API.

## Requirements

Windows Steam desktop and Millennium. Target the current stable Millennium 3.6.2 for runtime validation; the official template declares 3.4.0 as its minimum. Neither version has been runtime-tested here. Development requires Node.js/npm; storage tests additionally require Python 3.10+ and Lupa 2.6. React is supplied by Steam; no React runtime is bundled.

## Local development and build

```powershell
npm ci
npm run typecheck
npm test
python -m pip install --target .tools -r tests/requirements.txt
npm run test:storage
npm run build
npx --no-install starlight verify dist/steam-nexus.star
```

`npm ci` generates Millennium declarations through the template's `prepare` hook. If needed, regenerate them with `npm run prepare`. `npm run dev` runs the official Starlight watcher; live reload requires a working Millennium runtime. `npm run build` produces the ignored, unsigned `dist/steam-nexus.star`; it does not write into Steam. Node and Python dependencies are development tools only. Package versions are pinned in package-lock.json; Starlight npm 1.1.6 currently ships a Windows binary that reports 1.1.5.

With Steam running, `python tests/run_storage.py --local-steam` validates against local metadata using the production Lua scanner with a Python filesystem adapter. It prints aggregate counts only and changes no Steam files. This is not a Millennium integration test.

## Development installation

Install Millennium separately using its [official installation guide](https://docs.steambrew.app/). For the official template's automatic development installation, use a temporary local copy of millennium.toml with `[compiler] output_path = "auto"`, then run `npx --no-install starlight pack --config <local-config-file>` and enable Steam Nexus in Millennium Settings. Keep that local config out of Git. The checked-in configuration deliberately builds a local artifact. Installation and discovery remain untested; no plugin was installed into Steam during this work.

## Configuration

Millennium owns persistence. The backend supplies these defaults only when absent:

| Key | Default | Status |
| --- | --- | --- |
| `drive-indicators.enabled` | `true` | Enables metadata loading; disabling clears cached data |
| `drive-indicators.format` | `brackets` | Reserved preference: `brackets` or `plain`; display pending |
| `drive-indicators.showPath` | `true` | Reserved hover preference; display pending |

Only the enabled setting affects the current foundation. Native settings controls will be added after sidebar runtime validation. The frontend subscribes to enabled changes and disposes its subscription and features on dismount. `getInstallationsJson()` reads the cache; `refreshInstallationsJson()` invalidates it and rescans. No automatic installation-change event or polling is implemented. Refresh after installs, moves or removals requires the refresh RPC or a plugin reload for now.

## Structure

```text
backend/
  main.lua
  rpc.lua
  storage/{vdf,installations,service}.lua
frontend/
  index.tsx
  core/{lifecycle,settings}.ts
  features/drive-indicators/index.ts
tests/
  lifecycle.test.cjs
  storage_spec.lua
  run_storage.py
  requirements.txt
docs/
  framework.md
  validation.md
millennium.toml
```

## Limitations and next milestone

The sidebar adapter, badges, formatting/hover behaviour and settings controls await stage 4/5 runtime work. No guessed selectors, undocumented Steam APIs or legacy Millennium window hooks were added. Storage is Windows drive-letter based; UNC libraries and non-Windows clients are unsupported. Fully installed manifests require the installed state flag and an existing game directory. A disconnected library is omitted. Duplicate AppIDs across libraries choose the first path in sorted order; reconcile with Steam's active installation before publishing. Library file races can omit an entry until refresh. Parsing is bounded to 4 MiB per metadata file and 64 nested objects.

See [validation and manual checks](docs/validation.md) and [framework/distribution research](docs/framework.md). The next milestone is a supported Millennium sidebar proof of concept based on actual current Steam code, followed by settings controls and runtime lifecycle testing.

## Distribution and licence

This scaffold was created with AI assistance. Millennium's current submission rules prohibit primarily AI-generated plugins and require disclosure of assistance. This project is not eligible for submission as-is and has not been submitted or approved. Future distribution requires human ownership, review, ongoing maintenance and compliance with the rules then in effect.

No project licence has been selected. MIT is a recommendation for your confirmation. Review upstream template licensing before distribution; no licence file was present at the recorded template commit. No remote repository was created and nothing was pushed.
