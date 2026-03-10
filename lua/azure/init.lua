local M = {}

local fetch = require("azure.fetch")

-- Holds the resolved config after setup() is called
local config = {}

function M.setup(opts)
	opts = opts or {}

	config = {
		decrypt = opts.decrypt or false,
		key_vault_name = opts.key_vault_name or nil,
		output_path = opts.output_path or nil,
		open_file = opts.open_file ~= false, -- default true
	}

	local keymaps = opts.keymaps or {}
	local fetch_key = keymaps.fetch_app_settings or "<leader>af"

	vim.keymap.set("n", fetch_key, function()
		fetch.fetch_app_settings(config)
	end, { noremap = true, silent = true, desc = "Azure: fetch Function App settings" })

	vim.api.nvim_create_user_command("AzFetchAppSettings", function()
		fetch.fetch_app_settings(config)
	end, { desc = "Fetch Azure Function App settings" })
end

return M
