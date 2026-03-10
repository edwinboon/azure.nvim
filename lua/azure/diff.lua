local M = {}

-- Compute diff between two flat key→value tables.
-- Returns { added, changed, unchanged, azure_only }
-- added      = in local, not in Azure (will be pushed)
-- changed    = in both, different value
-- unchanged  = in both, same value
-- azure_only = in Azure, not in local (left untouched on push)
function M.compute(local_values, azure_values)
	local result = {
		added = {},
		changed = {},
		unchanged = {},
		azure_only = {},
	}

	for key, value in pairs(local_values) do
		if azure_values[key] == nil then
			result.added[key] = value
		elseif tostring(azure_values[key]) ~= tostring(value) then
			result.changed[key] = { local_val = value, azure_val = azure_values[key] }
		else
			result.unchanged[key] = value
		end
	end

	for key, value in pairs(azure_values) do
		if local_values[key] == nil then
			result.azure_only[key] = value
		end
	end

	return result
end

-- Show diff in a scratch buffer split.
-- Returns buf, win so callers can close it programmatically.
function M.show(diff_result, title)
	local lines = {}
	local highlights = {} -- { line, group }

	local function section(label, keys, format_fn, hl_group)
		if #keys == 0 then return end
		table.sort(keys)
		table.insert(lines, label)
		table.insert(highlights, { #lines - 1, "Comment" })
		for _, key in ipairs(keys) do
			local line = format_fn(key)
			table.insert(lines, line)
			table.insert(highlights, { #lines - 1, hl_group })
		end
		table.insert(lines, "")
	end

	table.insert(lines, " " .. (title or "Azure diff"))
	table.insert(highlights, { 0, "Title" })
	table.insert(lines, "")

	section(
		" + New (local only — will be pushed)",
		vim.tbl_keys(diff_result.added),
		function(k) return "   + " .. k .. " = " .. tostring(diff_result.added[k]) end,
		"DiffAdd"
	)

	section(
		" ~ Changed",
		vim.tbl_keys(diff_result.changed),
		function(k)
			local e = diff_result.changed[k]
			return "   ~ " .. k .. "\n       azure: " .. tostring(e.azure_val) .. "\n       local: " .. tostring(e.local_val)
		end,
		"DiffChange"
	)

	-- Flatten multiline entries
	local flat_lines = {}
	local flat_highlights = {}
	local hl_idx = 1
	for _, raw in ipairs(lines) do
		for _, l in ipairs(vim.split(raw, "\n", { plain = true })) do
			table.insert(flat_lines, l)
			if hl_idx <= #highlights and highlights[hl_idx][1] == #flat_lines - 1 then
				table.insert(flat_highlights, { #flat_lines - 1, highlights[hl_idx][2] })
				hl_idx = hl_idx + 1
			end
		end
	end

	section(
		" = Unchanged",
		vim.tbl_keys(diff_result.unchanged),
		function(k) return "   = " .. k end,
		"Comment"
	)

	section(
		" - Azure only (will not be changed)",
		vim.tbl_keys(diff_result.azure_only),
		function(k) return "   - " .. k end,
		"DiffDelete"
	)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, flat_lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

	for _, hl in ipairs(flat_highlights) do
		vim.api.nvim_buf_add_highlight(buf, -1, hl[2], hl[1], 0, -1)
	end

	vim.cmd("botright split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_win_set_height(win, math.min(#flat_lines + 2, 20))

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, { buffer = buf, nowait = true })

	return buf, win
end

-- Safely close the diff window (no-op if already closed)
function M.close(win)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

return M
