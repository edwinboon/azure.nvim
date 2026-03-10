local M = {}

local fetch = require("azure.fetch")

-- Holds the resolved config after setup() is called
local config = {}

function M.setup(opts)
	opts = opts or {}

	local key_vault_name = opts.key_vault_name
	if key_vault_name ~= nil and type(key_vault_name) ~= "string" then
		vim.notify("azure.nvim: key_vault_name must be a string", vim.log.levels.ERROR)
		return
	end
	if key_vault_name == "" then key_vault_name = nil end

	local output_path = opts.output_path
	if output_path ~= nil and type(output_path) ~= "string" then
		vim.notify("azure.nvim: output_path must be a string", vim.log.levels.ERROR)
		return
	end
	if output_path == "" then output_path = nil end

	if opts.decrypt ~= nil and type(opts.decrypt) ~= "boolean" then
		vim.notify("azure.nvim: decrypt must be a boolean", vim.log.levels.ERROR)
		return
	end

	if opts.open_file ~= nil and type(opts.open_file) ~= "boolean" then
		vim.notify("azure.nvim: open_file must be a boolean", vim.log.levels.ERROR)
		return
	end

	config = {
		decrypt = opts.decrypt or false,
		key_vault_name = key_vault_name,
		output_path = output_path,
		open_file = opts.open_file ~= false, -- default true
	}

	local keymaps = opts.keymaps
	if keymaps ~= nil and type(keymaps) ~= "table" then
		vim.notify("azure.nvim: keymaps must be a table", vim.log.levels.ERROR)
		return
	end
	keymaps = keymaps or {}

	local fetch_key = keymaps.fetch_app_settings
	if fetch_key ~= nil and type(fetch_key) ~= "string" then
		vim.notify("azure.nvim: keymaps.fetch_app_settings must be a string", vim.log.levels.ERROR)
		return
	end
	if not fetch_key or fetch_key == "" then
		fetch_key = "<leader>af"
	end

	vim.keymap.set("n", fetch_key, function()
		fetch.fetch_app_settings(config)
	end, { noremap = true, silent = true, desc = "Azure: fetch Function App settings" })

	vim.api.nvim_create_user_command("AzFetchAppSettings", function()
		fetch.fetch_app_settings(config)
	end, { desc = "Fetch Azure Function App settings" })
end

return M
