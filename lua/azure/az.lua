local M = {}

-- Run an Azure CLI command and return the output, or nil on error.
-- Accepts an argv table so arguments are never split or shell-interpreted.
-- Uses vim.system() (Neovim 0.9+) to keep stdout and stderr separate.
-- Falls back to vim.fn.system() for older Neovim versions.
function M.run_az_command(args)
	if vim.system then
		local proc = vim.system(args, { text = true }):wait()
		if proc.code ~= 0 then
			local err = (proc.stderr ~= "" and proc.stderr) or proc.stdout
			return nil, err
		end
		return proc.stdout, nil
	end

	local parts = vim.tbl_map(vim.fn.shellescape, args)
	local output = vim.fn.system(table.concat(parts, " ") .. " 2>&1")
	if vim.v.shell_error ~= 0 then
		return nil, output
	end
	return output, nil
end

-- Fetch app settings from Azure and return a flat key→value table, or nil on error.
function M.fetch_app_settings(app_name, resource_group)
	local args = {
		"az", "functionapp", "config", "appsettings", "list",
		"--name", app_name,
		"--resource-group", resource_group,
		"--query", "[].{name:name, value:value}",
		"-o", "json",
	}

	local result, err = M.run_az_command(args)
	if not result then
		vim.notify(
			"Failed to fetch Azure settings:\n" .. err .. "\nTip: make sure you are logged in with `az login`.",
			vim.log.levels.ERROR
		)
		return nil
	end

	local ok, settings = pcall(vim.fn.json_decode, result)
	if not ok or not settings then
		vim.notify(
			"Failed to decode Azure settings — az did not return valid JSON.\n" .. tostring(settings),
			vim.log.levels.ERROR
		)
		return nil
	end

	local values = {}
	for _, s in ipairs(settings) do
		values[s.name] = s.value
	end
	return values
end

return M
