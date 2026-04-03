local function should_expand_rust_block(before_cursor, after_cursor)
	if after_cursor ~= "" and not after_cursor:match("^%s*}?%s*$") then
		return false
	end

	local trimmed = before_cursor:gsub("%s+$", "")
	if trimmed == "" then
		return false
	end

	local looks_like_block_header = trimmed:match("%f[%a](fn|if|else|for|while|loop|match|impl|trait|mod|enum|struct)%f[%A]")
	if not looks_like_block_header then
		return false
	end

	return true
end

vim.keymap.set("i", "{", function()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1] or ""
	local before_cursor = line:sub(1, col)
	local after_cursor = line:sub(col + 1)

	if should_expand_rust_block(before_cursor, after_cursor) then
		return "{<CR><CR>}<Esc>kA"
	end

	return "{"
end, { buffer = true, expr = true, silent = true, desc = "Rust block brace expansion" })
