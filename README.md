# azure.nvim

A Neovim plugin to fetch and optionally decrypt Azure Function App settings directly from your editor.

## Features

- Fetch settings from an Azure Function App.
- Optionally decrypt the settings after fetching.
- Dynamic resource group handling for each fetch operation.
- Configurable keybindings and commands.

---

## Prerequisites

Before using this plugin, make sure you have the following tools installed and configured:

1. **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/):**
   - Required for fetching and decrypting Azure Function App settings.
   - Ensure you are logged in using `az login`:
     ```bash
     az login
     ```

---

## Installation

You can install `azure.nvim` using your favorite plugin manager. Here's how:

### Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require("lazy").setup({
    {
        "edwinboon/azure.nvim",
        version = "v0.2.0", -- Pin to a specific version
        config = function()
            require("azure").setup({
                decrypt = true, -- Enable decryption
                keymaps = {
                    fetch_app_settings = "<leader>af", -- Custom keybinding for fetching app settings
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
    tag = "v0.2.0", -- Pin to a specific version
    config = function()
        require("azure").setup({
            decrypt = true, -- Enable decryption
            keymaps = {
                fetch_app_settings = "<leader>af", -- Custom keybinding for fetching app settings
            },
        })
    end,
}
```

---

## Usage

1. **Keybinding**:

   - Press the configured keybinding (default: `<leader>af`) in normal mode.
   - Enter the name of the Azure Function App when prompted.
   - Enter the name of the Azure Resource Group when prompted.
   - The settings will be fetched, and optionally decrypted if `decrypt` is enabled.

2. **Command**:
   - Alternatively, you can use the command `:AzFetchAppSettings` to fetch the settings.
   - This is useful if you prefer not to use keybindings.

---

## Configuration Options

| Option            | Type    | Default | Description                                                                 |
| ----------------- | ------- | ------- | --------------------------------------------------------------------------- |
| `decrypt`         | boolean | `false` | Whether to decrypt `ENC(...)` values after fetching.                        |
| `key_vault_name`  | string  | `nil`   | Azure Key Vault name used for decryption (optional, only used with `decrypt = true`). |
| `output_path`     | string  | `nil`   | Directory to write `local.settings.json` to. Defaults to current working directory. |
| `open_file`       | boolean | `true`  | Whether to open `local.settings.json` in the editor after saving.           |
| `keymaps`         | table   | `{}`    | Table of keybindings for specific plugin actions.                           |

### Keymaps Table

The `keymaps` table allows you to define custom keybindings for specific plugin functions:

| Key                  | Description                                              |
| -------------------- | -------------------------------------------------------- |
| `fetch_app_settings` | Keybinding to fetch and optionally decrypt app settings. |

---

## Example Configuration

Here's a sample configuration for your `init.lua`:

```lua
require("azure").setup({
    decrypt = true, -- Enable decryption after fetching
    keymaps = {
        fetch_app_settings = "<leader>af", -- Set a custom keybinding for fetching app settings
    },
})
```

If you prefer using commands, you can skip the `keymaps` option and use `:AzFetchAppSettings` instead.

---

## License

This plugin is licensed under the MIT License. See [LICENSE](LICENSE) for details.
