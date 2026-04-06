local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config["lua_ls"] = {
	capabilities = capabilities,
}

vim.lsp.config["nixd"] = {
	capabilities = capabilities,
}

vim.lsp.config["rust_analyzer"] = {
	capabilities = capabilities,
}

vim.lsp.config["pylsp"] = {
	capabilities = capabilities,
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

vim.lsp.config["ts_ls"] = {
	capabilities = capabilities,
}

vim.lsp.enable({ "lua_ls", "nixd", "rust_analyzer", "pylsp", "ts_ls" })

vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)

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

		if client:supports_method("textDocument/semanticTokens/full")
			or client:supports_method("textDocument/semanticTokens/range") then
			vim.lsp.semantic_tokens.enable(true, { bufnr = ev.buf })
		end
	end,
})
