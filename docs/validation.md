# Validation and remaining work

Validated 29 October 2026. This report covers stages 1-3 only; Steam integration is unverified.

## Results

| Check | Result |
| --- | --- |
| TypeScript strict checks configured by template | Passed |
| Lifecycle tests | 4 passed |
| Production Lua storage/configuration tests under LuaJIT 2.1 (Lupa 2.6) | 11 passed |
| Local production scanner with filesystem adapter | 22 installed apps across 2 drives; 1 inaccessible library skipped; 0 invalid manifests; no library metadata warning |
| Starlight pack | Passed; unsigned .star artifact |
| Starlight verify | All archive sections verified; plugin ID steam-nexus, version 0.1.0 |
| npm dependency audit during installation | 0 vulnerabilities reported |
| Millennium discovery, FFI runtime and persistence between Steam sessions | Not tested; Millennium not found locally |
| Library indicators, native interactions, settings controls and theme behaviour | Not implemented/tested; stages 4-5 pending |

Storage tests cover multiple drives, AppID matching, malformed manifests, installed flags, missing game directories, inaccessible libraries, path traversal, primary-library fallback, old library entries, deduplication, VDF escapes/comments/BOM/limits, cache refresh and mocked backend default preservation/cache cleanup. Configuration tests use a mocked API and do not prove Millennium persistence. Local validation reads actual metadata without committing game names or personal paths. The production fs/millennium/cjson host modules are not exercised by the filesystem adapter test.

The four lifecycle tests cover rapid toggles, duplicate prevention, disposal, failed-enable cleanup, recovery after failure, independent cleanup after a feature failure, duplicate IDs and unknown features.

## Manual validation sequence

1. Set up stable Millennium 3.6.2 in a supported Windows Steam environment. Follow README development installation instructions; confirm the plugin is discovered and its native information field appears.
2. Confirm backend readiness and both generated JSON RPCs work in the real host, including fs.list, io.open, config and JSON encoding. Compare mappings against Steam Storage settings, including duplicate AppIDs across libraries.
3. Inspect the live Library row implementation and current Steam bundles. Use the documented hooking mechanism to mount a small native-looking indicator with an AppID prop. Keep any required Steam patch/DOM adaptation inside one feature-specific sidebar adapter. No suitable row hook has been identified or validated yet.
4. Prove one installed game indicator, then expand to visible virtualized rows. Check scrolling, filtering, categories, long names, recycled rows and uninstalled games. Avoid rescanning the full DOM or filesystem per row.
5. Add native ToggleField/Dropdown controls for the existing settings namespace. Wire format/hover changes to visible rows. Confirm preferences persist through a Steam restart and toggling the feature removes all injected UI and listeners.
6. Validate game installation, uninstallation and movement between drives. Identify a verified event or explicit refresh control for cache invalidation; no automatic event API is assumed. Test library disconnect/reconnect, partial metadata writes and denied access.
7. Check click/double-click/context menus, accessibility, sidebar resizing and compatible themes. Verify repeated enable/disable and plugin reload produce no duplicate indicators or leaks.
8. Recheck archive, metadata, licensing, AI disclosure and current submission restrictions before considering distribution. No publication pipeline is configured.

## Versions

- Project: 0.1.0.
- Millennium target researched: stable 3.6.2; official template minimum: 3.4.0.
- Official template base: af0a07c7c90de902333ab5268e53ac1bf73bed36.
- Starlight npm: 1.1.6; bundled Windows compiler reports 1.1.5.
- TypeScript: 5.9.3.
- React/React DOM type packages: 19.1.1; runtime supplied by Steam.
- Test-only Lupa: 2.6, using its LuaJIT 2.1 module.

Code contains no explanatory comments. Lua FFI annotations are retained because the compiler requires them. Development notes live in Markdown.
