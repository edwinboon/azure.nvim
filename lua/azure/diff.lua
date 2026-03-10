local M = {}

-- Compute diff between two flat key→value tables.
-- Returns { added, changed, unchanged, azure_only }
-- added      = in local_values, not in azure_values
-- changed    = in both, different value
-- unchanged  = in both, same value
-- azure_only = in azure_values, not in local_values
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
-- opts.labels overrides section headers for context-specific messaging.
-- Returns buf, win so callers can close it programmatically.
function M.show(diff_result, title, opts)
	opts = opts or {}
	local labels = opts.labels or {
		added     = " + New (local only — will be pushed)",
		changed   = " ~ Changed",
		unchanged = " = Unchanged",
		azure_only = " - Azure only (will not be changed)",
	}

	local lines = {}
	local highlights = {} -- { line_index, hl_group }

	local function add(line, hl_group)
		table.insert(lines, line)
		if hl_group then
			table.insert(highlights, { #lines - 1, hl_group })
		end
	end

	local function section(label, keys, format_fn, hl_group)
		if #keys == 0 then return end
		table.sort(keys)
		add(label, "Comment")
		for _, key in ipairs(keys) do
			for _, l in ipairs(vim.split(format_fn(key), "\n", { plain = true })) do
				add(l, hl_group)
			end
		end
		add("")
	end

	add(" " .. (title or "Azure diff"), "Title")
	add("")

	section(
		labels.added,
		vim.tbl_keys(diff_result.added),
		function(k) return "   + " .. k .. " = " .. tostring(diff_result.added[k]) end,
		"DiffAdd"
	)

	section(
		labels.changed,
		vim.tbl_keys(diff_result.changed),
		function(k)
			local e = diff_result.changed[k]
			return "   ~ " .. k .. "\n       azure: " .. tostring(e.azure_val) .. "\n       local: " .. tostring(e.local_val)
		end,
		"DiffChange"
	)

	section(
		labels.unchanged,
		vim.tbl_keys(diff_result.unchanged),
		function(k) return "   = " .. k end,
		"Comment"
	)

	section(
		labels.azure_only,
		vim.tbl_keys(diff_result.azure_only),
		function(k) return "   - " .. k end,
		"DiffDelete"
	)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"

	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(buf, -1, hl[2], hl[1], 0, -1)
	end

	vim.cmd("botright split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_win_set_height(win, math.min(#lines + 2, 20))

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
