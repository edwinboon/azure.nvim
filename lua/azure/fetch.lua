local M = {}

-- Run an Azure CLI command and return the output, or nil on error
local function run_az_command(cmd)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil, result
	end
	return result, nil
end

-- Prompt the user for input, returns nil if cancelled or empty
local function prompt(label)
	local value = vim.fn.input(label)
	if value == "" then
		return nil
	end
	return value
end

-- Decrypt any ENC(...) values by fetching them from Key Vault
local function decrypt_settings(settings, vault_name)
	for _, setting in ipairs(settings) do
		if setting.value:match("^ENC%(") then
			local cmd = "az keyvault secret show --name "
				.. vim.fn.shellescape(setting.name)
				.. " --vault-name "
				.. vim.fn.shellescape(vault_name)
				.. " --query value -o tsv"

			local decrypted, err = run_az_command(cmd)
			if decrypted then
				setting.value = vim.trim(decrypted)
			else
				vim.notify(
					"Failed to decrypt '" .. setting.name .. "': " .. err,
					vim.log.levels.WARN
				)
			end
		end
	end
end

-- Convert a flat list of {name, value} settings to local.settings.json format
local function build_local_settings(settings)
	local output = {
		IsEncrypted = false,
		Values = {},
	}
	for _, setting in ipairs(settings) do
		output.Values[setting.name] = setting.value
	end
	return output
end

-- Write the settings table to a file as formatted JSON
local function write_settings(data, output_file)
	local json_str = vim.json.encode(data)

	local file = io.open(output_file, "w")
	if not file then
		vim.notify("Failed to write to " .. output_file, vim.log.levels.ERROR)
		return false
	end

	file:write(json_str)
	file:close()
	return true
end

-- Main entry point: fetch app settings and save to local.settings.json
function M.fetch_app_settings(config)
	config = config or {}

	local app_name = prompt("Azure Function App name: ")
	if not app_name then
		vim.notify("Cancelled: app name is required.", vim.log.levels.WARN)
		return
	end

	local resource_group = prompt("Azure Resource Group: ")
	if not resource_group then
		vim.notify("Cancelled: resource group is required.", vim.log.levels.WARN)
		return
	end

	vim.notify("Fetching settings for " .. app_name .. "...", vim.log.levels.INFO)

	local cmd = "az functionapp config appsettings list"
		.. " --name " .. vim.fn.shellescape(app_name)
		.. " --resource-group " .. vim.fn.shellescape(resource_group)
		.. " --query '[].{name:name, value:value}' -o json"

	local result, err = run_az_command(cmd)
	if not result then
		vim.notify(
			"Error fetching settings:\n" .. err .. "\nTip: make sure you are logged in with `az login`.",
			vim.log.levels.ERROR
		)
		return
	end

	local settings = vim.fn.json_decode(result)
	if not settings or #settings == 0 then
		vim.notify("No settings found for " .. app_name .. ".", vim.log.levels.WARN)
		return
	end

	if config.decrypt then
		if not config.key_vault_name then
			vim.notify(
				"Decryption enabled but 'key_vault_name' is not set in config.",
				vim.log.levels.ERROR
			)
			return
		end
		decrypt_settings(settings, config.key_vault_name)
	end

	local local_settings = build_local_settings(settings)

	local output_file = (config.output_path or vim.fn.getcwd()) .. "/local.settings.json"

	if not write_settings(local_settings, output_file) then
		return
	end

	vim.notify("Settings saved to " .. output_file, vim.log.levels.INFO)

	if config.open_file ~= false then
		vim.cmd("edit " .. vim.fn.fnameescape(output_file))
	end
end

return M
