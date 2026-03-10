local M = {}

local az = require("azure.az")
local select = require("azure.select")
local diff = require("azure.diff")

-- Read and parse local.settings.json, returns the Values table or nil on error
local function load_local_settings(config)
	local output_dir = vim.fn.expand(config.output_path or vim.fn.getcwd())
	local path = output_dir .. "/local.settings.json"

	local uv = vim.uv or vim.loop
	if not uv.fs_stat(path) then
		vim.notify("local.settings.json not found at " .. path, vim.log.levels.ERROR)
		return nil
	end

	local file = io.open(path, "r")
	if not file then
		vim.notify("Failed to read " .. path, vim.log.levels.ERROR)
		return nil
	end

	local content = file:read("*a")
	file:close()

	local ok, data = pcall(vim.fn.json_decode, content)
	if not ok or not data or not data.Values then
		vim.notify("Failed to parse local.settings.json — invalid JSON.", vim.log.levels.ERROR)
		return nil
	end

	return data.Values
end

-- Fetch current Azure settings as a flat key→value table
local function fetch_azure_values(app_name, resource_group)
	local args = {
		"az", "functionapp", "config", "appsettings", "list",
		"--name", app_name,
		"--resource-group", resource_group,
		"--query", "[].{name:name, value:value}",
		"-o", "json",
	}

	local result, err = az.run_az_command(args)
	if not result then
		vim.notify(
			"Failed to fetch Azure settings:\n" .. err .. "\nTip: make sure you are logged in with `az login`.",
			vim.log.levels.ERROR
		)
		return nil
	end

	local settings = vim.fn.json_decode(result)
	if not settings then
		vim.notify("Failed to decode Azure settings.", vim.log.levels.ERROR)
		return nil
	end

	local values = {}
	for _, s in ipairs(settings) do
		values[s.name] = s.value
	end
	return values
end

-- Perform the actual push after inputs have been collected
local function do_push(config, app_name, resource_group)
	local local_values = load_local_settings(config)
	if not local_values then return end

	vim.notify("Fetching current Azure settings for " .. app_name .. "...", vim.log.levels.INFO)

	local azure_values = fetch_azure_values(app_name, resource_group)
	if not azure_values then return end

	local d = diff.compute(local_values, azure_values)

	local to_push = {}
	for key, value in pairs(d.added) do
		to_push[key] = value
	end
	for key, entry in pairs(d.changed) do
		to_push[key] = entry.local_val
	end

	if vim.tbl_count(to_push) == 0 then
		vim.notify("Nothing to push — local settings match Azure.", vim.log.levels.INFO)
		return
	end

	local _, win = diff.show(d, "Push diff: " .. app_name)

	vim.ui.select({ "Yes", "No" }, {
		prompt = "Push " .. vim.tbl_count(to_push) .. " new/changed setting(s) to " .. app_name .. "?",
	}, function(choice)
		diff.close(win)

		if choice ~= "Yes" then
			vim.notify("Push cancelled.", vim.log.levels.WARN)
			return
		end

		vim.notify("Pushing " .. vim.tbl_count(to_push) .. " setting(s) to " .. app_name .. "...", vim.log.levels.INFO)

		local args = {
			"az", "functionapp", "config", "appsettings", "set",
			"--name", app_name,
			"--resource-group", resource_group,
			"--settings",
		}
		for key, value in pairs(to_push) do
			table.insert(args, key .. "=" .. tostring(value))
		end

		local result, err = az.run_az_command(args)
		if not result then
			vim.notify("Failed to push settings:\n" .. err, vim.log.levels.ERROR)
			return
		end

		vim.notify(
			"Successfully pushed " .. vim.tbl_count(to_push) .. " setting(s) to " .. app_name .. ".",
			vim.log.levels.INFO
		)
	end)
end

-- Main entry point: select resource group and function app, then push
function M.push_app_settings(config)
	config = config or {}

	select.resource_group(function(resource_group)
		select.function_app(resource_group, function(app_name)
			do_push(config, app_name, resource_group)
		end)
	end)
end

return M
