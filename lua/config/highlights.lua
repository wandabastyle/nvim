local function get_group(name)
	local ok, group = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if not ok or vim.tbl_isempty(group) then
		return nil
	end
	return group
end

local function styled_from(source, style)
	local base = get_group(source) or {}
	base.link = nil
	return vim.tbl_extend("force", base, style)
end

local function apply_semantic_highlights()
	vim.api.nvim_set_hl(0, "@variable.parameter", styled_from("@parameter", { italic = true }))
	vim.api.nvim_set_hl(0, "@lsp.type.parameter", { link = "@variable.parameter" })

	vim.api.nvim_set_hl(0, "@lsp.typemod.variable.local", styled_from("@variable", { italic = true }))
	vim.api.nvim_set_hl(0, "@lsp.type.variable", { link = "@variable" })

	vim.api.nvim_set_hl(0, "@lsp.type.function", { link = "@function" })
	vim.api.nvim_set_hl(0, "@lsp.type.method", { link = "@function.method" })
	vim.api.nvim_set_hl(0, "@function.call", { link = "@function" })
	vim.api.nvim_set_hl(0, "@function.method.call", { link = "@function.method" })

	vim.api.nvim_set_hl(0, "@lsp.type.field", { link = "@field" })
	vim.api.nvim_set_hl(0, "@lsp.type.property", { link = "@property" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = apply_semantic_highlights,
})

apply_semantic_highlights()
