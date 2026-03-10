# azure.nvim

A Neovim plugin to fetch and optionally decrypt Azure Function App settings directly from your editor.

## Features

- Fetch settings from an Azure Function App and save them as `local.settings.json`.
- Optionally decrypt `ENC(...)` values using Azure Key Vault.
- Dynamic resource group handling for each fetch operation.
- Configurable keybindings and commands.
- Configurable output path and file-open behavior.

---

## Prerequisites

Before using this plugin, make sure you have the following installed and configured:

1. **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/):**
   - Required for fetching and decrypting Azure Function App settings.
   - Ensure you are logged in:
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
        version = "v0.3.0",
        config = function()
            require("azure").setup({
                keymaps = {
                    fetch_app_settings = "<leader>af",
                },
            })
        end,
    },
})
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "edwinboon/azure.nvim",
    tag = "v0.3.0",
    config = function()
        require("azure").setup({
            keymaps = {
                fetch_app_settings = "<leader>af",
            },
        })
    end,
}
```

---

## Usage

1. **Keybinding**: Press the configured keybinding (default: `<leader>af`) in normal mode.
2. **Command**: Run `:AzFetchAppSettings`.

You will be prompted for the Function App name and Resource Group. The settings will be fetched and saved as `local.settings.json` in the current working directory (or `output_path` if configured).

---

## Configuration Options

| Option           | Type    | Default | Description                                                                        |
| ---------------- | ------- | ------- | ---------------------------------------------------------------------------------- |
| `decrypt`        | boolean | `false` | Attempt to decrypt `ENC(...)` values after fetching.                               |
| `key_vault_name` | string  | `nil`   | Azure Key Vault name used for decryption. Required when `decrypt = true` and settings contain `ENC(...)` values. |
| `output_path`    | string  | `nil`   | Directory to write `local.settings.json` to. Defaults to current working directory. |
| `open_file`      | boolean | `true`  | Whether to open `local.settings.json` in the editor after saving.                  |
| `keymaps`        | table   | `{}`    | Table of keybindings for plugin actions.                                           |

### Keymaps Table

| Key                  | Default       | Description                                        |
| -------------------- | ------------- | -------------------------------------------------- |
| `fetch_app_settings` | `<leader>af`  | Fetch and optionally decrypt Function App settings. |

---

## Decryption

When `decrypt = true`, the plugin will look for settings whose value starts with `ENC(...)` and attempt to retrieve the plaintext value from Azure Key Vault.

The secret name is resolved as follows:
- If the content inside `ENC(...)` is a valid Key Vault secret name (letters, numbers, hyphens), that name is used.
- Otherwise, the app setting name is used as the secret name.

**Examples:**

| App setting value       | Secret name used in Key Vault |
| ----------------------- | ----------------------------- |
| `ENC(my-secret-name)`   | `my-secret-name`              |
| `ENC(<encrypted-blob>)` | the app setting name          |

**Example configuration with decryption:**

```lua
require("azure").setup({
    decrypt = true,
    key_vault_name = "my-keyvault",
    keymaps = {
        fetch_app_settings = "<leader>af",
    },
})
```

---

## Example Configuration

Minimal setup:

```lua
require("azure").setup({
    keymaps = {
        fetch_app_settings = "<leader>af",
    },
})
```

Full configuration:

```lua
require("azure").setup({
    decrypt = true,
    key_vault_name = "my-keyvault",
    output_path = "/path/to/project",
    open_file = true,
    keymaps = {
        fetch_app_settings = "<leader>af",
    },
})
```

If you prefer commands over keybindings, skip the `keymaps` option and use `:AzFetchAppSettings` instead.

---

## Troubleshooting

**Error fetching settings**
- Make sure you are logged in with `az login`.
- Verify the Function App name and Resource Group are correct.

**Decryption fails**
- Make sure `key_vault_name` is set in your config.
- Ensure you have read access to the Key Vault secrets.

---

## License

This plugin is licensed under the MIT License. See [LICENSE](LICENSE) for details.
