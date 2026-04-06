vim.lsp.config["nil_ls"] = {}

vim.lsp.config["pylsp"] = {
	settings = {
		pylsp = {
			plugins = {
				pycodestyle = { enabled = false },
				mccabe = { enabled = false },
				pyflakes = { enabled = false },
				autopep8 = { enabled = false },
				yapf = { enabled = false },
				black = { enabled = true },
				pylsp_mypy = { enabled = false },
			},
		},
	},
}

vim.lsp.config["ts_ls"] = {}

vim.lsp.enable({ "lua_ls", "nil_ls", "rust_analyzer", "pylsp", "ts_ls" })

vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("i", "<C-Space>", function() vim.lsp.completion.get() end,
	{ silent = true, desc = "Trigger LSP completion" })

for k, v in pairs({
	["<Tab>"] = { complete = "<C-n>", fallback = "<Tab>", direction = 1 },
	["<S-Tab>"] = { complete = "<C-p>", fallback = "<S-Tab>", direction = -1 },
}) do
	vim.keymap.set({ "i", "s" }, k, function()
		if vim.fn.pumvisible() == 1 then
			return v.complete
		end

		if vim.snippet.active({ direction = v.direction }) then
			vim.snippet.jump(v.direction)
			return ""
		end

		return v.fallback
	end, { expr = true, silent = true })
end

local autopairs = require("nvim-autopairs")

vim.keymap.set("i", "<CR>", function()
	if vim.fn.pumvisible() == 1 then
		if vim.fn.complete_info({ "selected" }).selected ~= -1 then
			return vim.api.nvim_replace_termcodes("<C-y>", true, true, true)
		end

		return vim.api.nvim_replace_termcodes("<C-e>", true, true, true) .. autopairs.autopairs_cr()
	end

	return autopairs.autopairs_cr()
end, { expr = true, replace_keycodes = false, silent = true, desc = "Confirm completion or autopairs newline" })

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		local opts = { buffer = ev.buf }

		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts)
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

		if client:supports_method("textDocument/completion") then
			local identifier_chars = {}
			for i = 32, 126 do
				local char = string.char(i)
				if char:match("[%w_]") then
					table.insert(identifier_chars, char)
				end
			end
			-- Some servers only auto-trigger completion on specific characters. Expanding
			-- triggerCharacters to identifier-like ASCII avoids punctuation-triggered popups.
			client.server_capabilities.completionProvider = client.server_capabilities.completionProvider or {}
			client.server_capabilities.completionProvider.triggerCharacters = identifier_chars
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end

		if client:supports_method("textDocument/semanticTokens/full")
			or client:supports_method("textDocument/semanticTokens/range") then
			vim.lsp.semantic_tokens.enable(true, { bufnr = ev.buf })
		end
	end,
})
