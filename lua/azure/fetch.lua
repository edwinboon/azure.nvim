local M = {}

local az = require("azure.az")
local select = require("azure.select")
local diff = require("azure.diff")

-- Resolve the Key Vault secret name from an ENC(...) value.
-- If the content inside ENC(...) is a valid secret name, use it directly.
-- Otherwise fall back to the app setting name.
local function resolve_secret_name(setting_name, enc_value)
	local inner = enc_value:match("^ENC%((.-)%)$")
	if inner and inner:match("^[a-zA-Z0-9-]+$") then
		return inner
	end
	return setting_name
end

-- Decrypt any ENC(...) values by fetching them from Key Vault
local function decrypt_settings(settings, vault_name)
	if not vault_name then
		local enc_count = 0
		for _, setting in ipairs(settings) do
			if type(setting.value) == "string" and setting.value:match("^ENC%(") then
				enc_count = enc_count + 1
			end
		end
		if enc_count > 0 then
			vim.notify(
				"Skipping decryption of " .. enc_count .. " ENC(...) value(s): key_vault_name is not configured.",
				vim.log.levels.WARN
			)
		end
		return
	end

	for _, setting in ipairs(settings) do
		if type(setting.value) == "string" and setting.value:match("^ENC%(") then
			local secret_name = resolve_secret_name(setting.name, setting.value)
			local args = {
				"az", "keyvault", "secret", "show",
				"--name", secret_name,
				"--vault-name", vault_name,
				"--query", "value",
				"-o", "tsv",
			}

			local decrypted, err = az.run_az_command(args)
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

-- Write the settings table to a file as JSON
local function write_settings(data, output_file)
	local json_str = vim.json.encode(data)

	local output_dir = vim.fn.fnamemodify(output_file, ":h")
	vim.fn.mkdir(output_dir, "p")

	local file, err = io.open(output_file, "w")
	if not file then
		vim.notify(
			"Failed to write to " .. output_file .. (err and (": " .. err) or ""),
			vim.log.levels.ERROR
		)
		return false
	end

	file:write(json_str)
	file:close()
	return true
end

-- Perform the actual fetch after inputs have been collected
local function do_fetch(config, app_name, resource_group)
	vim.notify("Fetching settings for " .. app_name .. "...", vim.log.levels.INFO)

	local azure_values = az.fetch_app_settings(app_name, resource_group)
	if not azure_values then return end

	-- Convert flat key→value table back to list format for decrypt_settings
	local settings = {}
	for k, v in pairs(azure_values) do
		table.insert(settings, { name = k, value = v })
	end

	if #settings == 0 then
		vim.notify("No settings found for " .. app_name .. ". Writing empty local.settings.json.", vim.log.levels.WARN)
	end

	if config.decrypt then
		decrypt_settings(settings, config.key_vault_name)
	end

	local local_settings = build_local_settings(settings)

	local output_dir = vim.fn.expand(config.output_path or vim.fn.getcwd())
	local output_file = output_dir .. "/local.settings.json"

	local function save_and_open()
		if not write_settings(local_settings, output_file) then
			return
		end
		vim.notify("Settings saved to " .. output_file, vim.log.levels.INFO)
		if config.open_file ~= false then
			vim.cmd("edit " .. vim.fn.fnameescape(output_file))
		end
	end

	local uv = vim.uv or vim.loop
	if uv.fs_stat(output_file) then
		-- Try to load existing file for diff
		local existing_values = nil
		local existing_file, open_err = io.open(output_file, "r")
		if not existing_file then
			vim.notify(
				"Could not read existing local.settings.json" .. (open_err and (": " .. open_err) or "") .. " — showing overwrite confirmation instead of diff.",
				vim.log.levels.WARN
			)
		else
			local content = existing_file:read("*a")
			existing_file:close()
			local ok, existing_data = pcall(vim.fn.json_decode, content)
			if ok and existing_data and existing_data.Values then
				existing_values = existing_data.Values
			else
				vim.notify(
					"Could not parse existing local.settings.json" .. (not ok and (": " .. tostring(existing_data)) or "") .. " — showing overwrite confirmation instead of diff.",
					vim.log.levels.WARN
				)
			end
		end

		if existing_values then
			-- compute(existing, azure): local_val = existing, azure_val = new from Azure
			local d = diff.compute(existing_values, local_settings.Values)
			local _, win = diff.show(d, "Fetch diff: " .. app_name, {
				labels = {
					added      = " - Will be removed from local file",
					changed    = " ~ Will be updated in local file",
					unchanged  = " = Unchanged",
					azure_only = " + Will be added to local file",
				},
			})

			vim.ui.select({ "Yes", "No" }, {
				prompt = "Apply these changes to " .. output_file .. "?",
			}, function(choice)
				diff.close(win)
				if choice == "Yes" then
					save_and_open()
				else
					vim.notify("Cancelled: file not updated.", vim.log.levels.WARN)
				end
			end)
		else
			-- Fallback: simple overwrite confirmation
			vim.ui.select({ "Yes", "No" }, {
				prompt = output_file .. " already exists. Overwrite?",
			}, function(choice)
				if choice == "Yes" then
					save_and_open()
				else
					vim.notify("Cancelled: file not overwritten.", vim.log.levels.WARN)
				end
			end)
		end
	else
		save_and_open()
	end
end

-- Main entry point: select resource group and function app, then fetch settings
function M.fetch_app_settings(config)
	config = config or {}

	select.resource_group(function(resource_group)
		select.function_app(resource_group, function(app_name)
			do_fetch(config, app_name, resource_group)
		end)
	end)
end

return M
