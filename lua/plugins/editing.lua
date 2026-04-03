require("nvim-autopairs").setup({})

local function should_expand_rust_block(before, after)
	if after:match("^%s*$") == nil then
		return false
	end

	local trimmed = before:gsub("%s+$", "")
	if trimmed == "" then
		return false
	end

	return trimmed:match("fn%s+[%w_]+%b()$")
		or trimmed:match("^if%s+.+$")
		or trimmed:match("^else%s+if%s+.+$")
		or trimmed:match("^else$")
		or trimmed:match("^match%s+.+$")
		or trimmed:match("^impl%s+.+$")
		or trimmed:match("^for%s+.+$")
		or trimmed:match("^while%s+.+$")
		or trimmed:match("^loop$")
end

local function rust_open_brace()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local before = line:sub(1, col)
	local after = line:sub(col + 1)

	if should_expand_rust_block(before, after) then
		return "{<CR>}<Esc>O"
	end

	return "{"
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "rust",
	callback = function(ev)
		vim.keymap.set("i", "{", rust_open_brace, {
			buffer = ev.buf,
			expr = true,
			silent = true,
			desc = "Rust block-aware open brace",
		})
	end,
})
