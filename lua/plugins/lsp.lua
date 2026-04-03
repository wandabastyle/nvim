vim.lsp.config["nixd"] = {
	settings = {
		nixd = {
			formatting = { command = { "nixfmt" } },
			nixpkgs = { expr = "import <nixpkgs> {}" },
			options = { nixos = { expr = "(import <nixpkgs/nixos> { configuration = {}; }).options" } },
		},
	},
}

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

vim.lsp.enable({ "lua_ls", "nixd", "rust_analyzer", "pylsp" })

vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("i", "<C-Space>", function() vim.lsp.completion.get() end,
	{ silent = true, desc = "Trigger LSP completion" })

for k, v in pairs({ ["<Tab>"] = { "<C-n>", "<Tab>" }, ["<S-Tab>"] = { "<C-p>", "<S-Tab>" }, ["<CR>"] = { "<C-y>", "<CR>" } }) do
	vim.keymap.set("i", k, function() return vim.fn.pumvisible() == 1 and v[1] or v[2] end, { expr = true, silent = true })
end

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
			local printable_ascii = {}
			for i = 32, 126 do
				table.insert(printable_ascii, string.char(i))
			end
			-- Some servers only auto-trigger completion on specific characters. Expanding
			-- triggerCharacters to printable ASCII helps identifier typing, but may be slower.
			client.server_capabilities.completionProvider = client.server_capabilities.completionProvider or {}
			client.server_capabilities.completionProvider.triggerCharacters = printable_ascii
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})
