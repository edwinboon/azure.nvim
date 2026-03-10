# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-03-10

### Added

- Push functionality: push new and changed settings from `local.settings.json` to Azure via `AzPushAppSettings` / `<leader>azp`
- Diff view: shows a colour-coded split before fetch and push operations with added, changed, unchanged and Azure-only settings
- New `lua/azure/diff.lua` module with `compute()` and `show()` helpers
- New `lua/azure/push.lua` module with full push flow
- New default keybindings: `<leader>azf` (fetch) and `<leader>azp` (push)
- New user command: `:AzPushAppSettings`

### Changed

- Fetch now shows a diff against the existing `local.settings.json` before overwriting, instead of a plain overwrite confirmation
- Default fetch keybinding changed from `<leader>af` to `<leader>azf`

## [0.4.0] - 2026-03-10

### Added

- Resource group dropdown via `vim.ui.select` — no more manual typing
- Function App dropdown via `vim.ui.select` — list is filtered by the selected resource group
- New `lua/azure/az.lua` module with shared `run_az_command()` — reusable across all features
- New `lua/azure/select.lua` module with `resource_group()` and `function_app()` pickers

### Changed

- `fetch_app_settings` now uses dropdowns instead of free-text input for both resource group and function app name

## [0.3.0] - 2026-03-10

### Changed

- Replaced `vim.fn.input()` with `vim.ui.input()` for user prompts — integrates automatically with UI plugins like `dressing.nvim` and `telescope-ui-select`
- Extracted fetch logic into a `do_fetch()` helper to keep callback nesting clean

### Added

- Confirmation prompt when `local.settings.json` already exists, using `vim.ui.select()` — prevents accidental overwrites

## [0.2.0] - 2026-03-10

### Changed

- Refactored `fetch.lua` into smaller, focused helper functions (`run_az_command`, `prompt`, `decrypt_settings`, `build_local_settings`, `write_settings`)
- Fixed shell injection vulnerability by applying `vim.fn.shellescape()` to all user inputs passed to Azure CLI
- Fixed path injection in `vim.cmd("edit ...")` by using `vim.fn.fnameescape()`
- Replaced all `print()` calls with `vim.notify()` using appropriate log levels
- Removed duplicate JSON encoding — now consistently uses `vim.json.encode()`
- Replaced `vim.api.nvim_set_keymap()` with `vim.keymap.set()` in `init.lua`
- Config is now passed as a table to `fetch_app_settings()` instead of loose booleans
- Added `desc` to keymap and user command (visible in `:map` and `which-key`)

### Added

- `key_vault_name` config option (optional, used when `decrypt = true` and settings contain `ENC(...)` values)
- Smart secret name resolution for `ENC(...)` values: uses the content inside `ENC(...)` if it is a valid Key Vault secret name, otherwise falls back to the app setting name
- `output_path` config option to set a custom output directory
- `open_file` config option to control whether the file opens after saving (default: `true`)
- Helpful error tip when Azure CLI fails: suggests running `az login`

## [0.1.3] - 2025-04-22

### Changed

- Fixed issue where the plugin was not doing anything with the app settings

## [0.1.2] - 2025-04-22

### Changed

- Fixed issue in fetch.lua for concatenating the azure command.

## [0.1.1] - 2025-04-22

### Changed

- Add option to enter resource group name
- Update README.md to include instructions for entering the resource group name.

## [0.1.0] - 2025-04-22

### Changed

- Renamed the plugin from `azfetch` to `azure` since it is now a general-purpose plugin for Azure.
- Added the fetch app settings functionality in a seperate lua file.
- Improved the README.md to provide better instructions on how to use the plugin.

## [0.0.3] - 2025-04-22

### Changed

- Improved README.md to make it easier to install the plugin.

## [0.0.2] - 2025-04-22

### Changed

- Fixed issue with loading the plugin due to mismatched folder name.

## [0.0.1] - 2025-04-22

### Added

- Initial release with the ability to fetch Azure Function App settings.
- Optional decryption of settings after fetching.
- Configurable keymap for triggering the fetch process.
