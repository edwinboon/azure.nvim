local M = {}

local run_az_command = require("azure.az").run_az_command

-- Show a vim.ui.select picker for Azure resource groups.
-- Calls callback(resource_group) on selection. Does not call callback on cancel or error.
function M.resource_group(callback)
	vim.notify("Loading resource groups...", vim.log.levels.INFO)

	local args = {
		"az", "group", "list",
		"--query", "[].name",
		"-o", "json",
	}

	local result, err = run_az_command(args)
	if not result then
		vim.notify("Failed to load resource groups:\n" .. err, vim.log.levels.ERROR)
		return
	end

	local groups = vim.fn.json_decode(result)
	if not groups or #groups == 0 then
		vim.notify("No resource groups found.", vim.log.levels.WARN)
		return
	end

	vim.ui.select(groups, { prompt = "Select resource group:" }, function(choice)
		if not choice then
			vim.notify("Cancelled.", vim.log.levels.WARN)
			return
		end
		callback(choice)
	end)
end

-- Show a vim.ui.select picker for Function Apps in the given resource group.
-- Calls callback(app_name) on selection. Does not call callback on cancel or error.
function M.function_app(resource_group, callback)
	vim.notify("Loading function apps...", vim.log.levels.INFO)

	local args = {
		"az", "functionapp", "list",
		"--resource-group", resource_group,
		"--query", "[].name",
		"-o", "json",
	}

	local result, err = run_az_command(args)
	if not result then
		vim.notify("Failed to load function apps:\n" .. err, vim.log.levels.ERROR)
		return
	end

	local apps = vim.fn.json_decode(result)
	if not apps or #apps == 0 then
		vim.notify("No function apps found in " .. resource_group .. ".", vim.log.levels.WARN)
		return
	end

	vim.ui.select(apps, { prompt = "Select function app:" }, function(choice)
		if not choice then
			vim.notify("Cancelled.", vim.log.levels.WARN)
			return
		end
		callback(choice)
	end)
end

return M
