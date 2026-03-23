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

-- Shared helper: build lines + highlights from a diff result.
-- Returns { lines, highlights } where highlights = { { line_index, hl_group }, ... }
local function build_lines(diff_result, title, opts)
	opts = opts or {}
	local labels = opts.labels or {
		added      = " + New (local only — will be pushed)",
		changed    = " ~ Changed",
		unchanged  = " = Unchanged",
		azure_only = " - Azure only (will not be changed)",
	}
	local changed_labels = opts.changed_labels or {
		before = "azure",
		after  = "local",
	}
	local swap = opts.swap or false

	local lines = {}
	local highlights = {}

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
		function(k) return "   " .. (swap and "-" or "+") .. " " .. k .. " = " .. tostring(diff_result.added[k]) end,
		swap and "DiffDelete" or "DiffAdd"
	)

	section(
		labels.changed,
		vim.tbl_keys(diff_result.changed),
		function(k)
			local e = diff_result.changed[k]
			local before_val = swap and e.local_val or e.azure_val
			local after_val  = swap and e.azure_val or e.local_val
			return "   ~ " .. k
				.. "\n       " .. changed_labels.before .. ": " .. tostring(before_val)
				.. "\n       " .. changed_labels.after  .. ": " .. tostring(after_val)
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
		function(k) return "   " .. (swap and "+" or "-") .. " " .. k end,
		swap and "DiffAdd" or "DiffDelete"
	)

	return lines, highlights
end

-- Show diff in a floating window with built-in confirm prompt.
-- on_confirm(true) = user chose yes, on_confirm(false) = cancelled/no.
-- Closing the window via any means (keymaps or :close/<C-w>c) always calls on_confirm(false).
function M.show_confirm(diff_result, title, prompt, on_confirm, opts)
	local lines, highlights = build_lines(diff_result, title, opts)

	-- Add confirmation footer
	table.insert(lines, "")
	table.insert(lines, " " .. (prompt or "Confirm?"))
	local footer_prompt_line = #lines - 1
	table.insert(lines, "  [y] Yes   [n] No")
	local footer_keys_line = #lines - 1

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"

	for _, hl in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(buf, -1, hl[2], hl[1], 0, -1)
	end
	vim.api.nvim_buf_add_highlight(buf, -1, "Title",   footer_prompt_line, 0, -1)
	vim.api.nvim_buf_add_highlight(buf, -1, "Comment", footer_keys_line,   0, -1)

	local ui = vim.api.nvim_list_uis()[1]
	local ui_width  = ui and ui.width  or 80
	local ui_height = ui and ui.height or 30
	local preferred_width  = math.min(80, ui_width - 4)
	local preferred_height = math.min(#lines + 2, math.floor(ui_height * 0.8))
	local width  = math.min(ui_width,  math.max(20, preferred_width))
	local height = math.min(ui_height, math.max(3,  preferred_height))
	local row = math.max(0, math.floor((ui_height - height) / 2))
	local col = math.max(0, math.floor((ui_width  - width)  / 2))

	local win = vim.api.nvim_open_win(buf, true, {
		relative  = "editor",
		width     = width,
		height    = height,
		row       = row,
		col       = col,
		style     = "minimal",
		border    = "rounded",
		noautocmd = true,
	})

	-- Guard to ensure on_confirm is called at most once
	local called = false
	local function confirm(yes)
		if called then return end
		called = true
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		on_confirm(yes)
	end

	vim.keymap.set("n", "y",     function() confirm(true)  end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "n",     function() confirm(false) end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q",     function() confirm(false) end, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", function() confirm(false) end, { buffer = buf, nowait = true })

	-- Catch window closed via :close, <C-w>c, or any other means
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once   = true,
		callback = function() confirm(false) end,
	})

	return buf, win
end

-- Show diff in a scratch buffer split.
-- opts.labels overrides section headers for context-specific messaging.
-- Returns buf, win so callers can close it programmatically.
function M.show(diff_result, title, opts)
	local lines, highlights = build_lines(diff_result, title, opts)

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
