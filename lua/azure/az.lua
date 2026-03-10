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

return M
