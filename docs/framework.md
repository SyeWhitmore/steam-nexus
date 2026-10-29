# Framework research

Reviewed 29 October 2026.

- Official template: https://github.com/SteamClientHomebrew/PluginTemplate at af0a07c7c90de902333ab5268e53ac1bf73bed36. Template history retained; upstream remote removed to prevent accidental pushes.
- Stable Millennium: https://github.com/SteamClientHomebrew/Millennium/releases/tag/v3.6.2. Template minimum is 3.4.0. No Millennium runtime was found in the local Steam directory.
- Starlight npm 1.1.6 (bundled Windows binary reports 1.1.5) uses millennium.toml, Lua backend, TypeScript/React frontend and compiles a .star archive. Generated bridge declarations come from `starlight lsp`; Lua `---@ffi` functions are exposed through generated `backend` calls. No legacy callServerMethod or window hook is used.
- Configuration: https://docs.steambrew.app/plugins/advanced/config documents `usePluginConfig`, `millennium.config.get/set/on_change`.
- Steam integration: https://docs.steambrew.app/plugins/advanced/hooking documents server-side JavaScript patches. There is no documented Library row hook. A row patch must be based on inspected current Steam code and validated in Millennium before implementation. Do not guess selectors or patches.
- Storage: https://docs.steambrew.app/plugins/lua/millennium documents steam_path; https://docs.steambrew.app/plugins/lua/fs documents fs.list.
- Submission: https://docs.steambrew.app/developers/submitting-plugins and https://github.com/SteamClientHomebrew/PluginDatabase. The database accepts the plugin repository as a submodule pinned to a specific commit. Updates require a PR advancing that pointer. Submission/update PRs require review and runtime testing. Primarily AI-generated plugins are prohibited; AI assistance must be disclosed. This AI-created development scaffold is not eligible for submission as-is. No approval or availability is claimed.

No project licence has been selected. The template repository contained no LICENSE file at the recorded commit. Review upstream licensing before distribution; do not infer a template licence from the documentation site's MIT footer.
