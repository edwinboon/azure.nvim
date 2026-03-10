# azure.nvim

A Neovim plugin to manage Azure Function App settings directly from your editor — fetch, diff, and push without leaving Neovim.

## Features

- Fetch settings from an Azure Function App and save them as `local.settings.json`.
- Push new and changed settings from `local.settings.json` back to Azure.
- Diff view before fetch and push — see exactly what will change.
- Resource group and Function App selection via dropdown (integrates with `dressing.nvim`, `telescope-ui-select`).
- Optionally decrypt `ENC(...)` values using Azure Key Vault.
- Configurable keybindings, output path, and file-open behavior.

---

## Prerequisites

1. **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)** — ensure you are logged in:
   ```bash
   az login
   ```

2. **Neovim 0.7+**

---

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require("lazy").setup({
    {
        "edwinboon/azure.nvim",
        version = "v0.5.0",
        config = function()
            require("azure").setup()
        end,
    },
})
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "edwinboon/azure.nvim",
    tag = "v0.5.0",
    config = function()
        require("azure").setup()
    end,
}
```

---

## Usage

### Fetch settings

Press `<leader>azf` or run `:AzFetchAppSettings`.

1. Select your Resource Group from a dropdown.
2. Select the Function App from a dropdown (filtered by resource group).
3. A diff view opens showing what will change compared to your current `local.settings.json`.
4. Confirm to save — the file is written and opened in the editor.

### Push settings

Press `<leader>azp` or run `:AzPushAppSettings`.

1. Select your Resource Group and Function App.
2. A diff view opens showing new and changed settings that will be pushed.
3. Confirm to push — only new and changed settings are sent to Azure. Settings that exist only in Azure are left untouched.

> **Tip:** Dropdowns integrate automatically with `dressing.nvim` or `telescope-ui-select`.

---

## Configuration Options

| Option           | Type    | Default | Description                                                                                     |
| ---------------- | ------- | ------- | ----------------------------------------------------------------------------------------------- |
| `decrypt`        | boolean | `false` | Attempt to decrypt `ENC(...)` values after fetching.                                            |
| `key_vault_name` | string  | `nil`   | Azure Key Vault name. Required when `decrypt = true` and settings contain `ENC(...)` values.    |
| `output_path`    | string  | `nil`   | Directory to write `local.settings.json` to. Defaults to current working directory.             |
| `open_file`      | boolean | `true`  | Whether to open `local.settings.json` in the editor after saving.                               |
| `keymaps`        | table   | `{}`    | Table of keybindings for plugin actions.                                                        |

### Keymaps Table

| Key                  | Default        | Description                                         |
| -------------------- | -------------- | --------------------------------------------------- |
| `fetch_app_settings` | `<leader>azf`  | Fetch Function App settings and save locally.       |
| `push_app_settings`  | `<leader>azp`  | Push new/changed local settings to Azure.           |

---

## Decryption

When `decrypt = true`, the plugin looks for settings whose value starts with `ENC(...)` and retrieves the plaintext from Azure Key Vault.

Secret name resolution:
- If the content inside `ENC(...)` is a valid Key Vault secret name (letters, numbers, hyphens) → that name is used.
- Otherwise → the app setting name is used as the secret name.

| App setting value       | Secret name used in Key Vault |
| ----------------------- | ----------------------------- |
| `ENC(my-secret-name)`   | `my-secret-name`              |
| `ENC(<encrypted-blob>)` | the app setting name          |

---

## Example Configuration

Minimal setup (uses all defaults):

```lua
require("azure").setup()
```

Full configuration:

```lua
require("azure").setup({
    decrypt = true,
    key_vault_name = "my-keyvault",
    output_path = "/path/to/project",
    open_file = true,
    keymaps = {
        fetch_app_settings = "<leader>azf",
        push_app_settings  = "<leader>azp",
    },
})
```

---

## Troubleshooting

**Error fetching or pushing settings**
- Make sure you are logged in with `az login`.
- Verify the Function App name and Resource Group are correct.

**Decryption fails**
- Make sure `key_vault_name` is set in your config.
- Ensure you have read access to the Key Vault secrets.

---

## License

This plugin is licensed under the MIT License. See [LICENSE](LICENSE) for details.
