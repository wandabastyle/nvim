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

vim.keymap.set("i", "<CR>",
	[[pumvisible() ? (complete_info(['selected']).selected != -1 ? "\<C-y>" : "\<C-e>" . v:lua.require'nvim-autopairs'.autopairs_cr()) : v:lua.require'nvim-autopairs'.autopairs_cr()]],
	{ expr = true, replace_keycodes = false, silent = true, desc = "Confirm completion or autopairs newline" })

local function completion_trigger_chars(client)
	local chars = {}

	if client.server_capabilities
		and client.server_capabilities.completionProvider
		and client.server_capabilities.completionProvider.triggerCharacters
	then
		for _, ch in ipairs(client.server_capabilities.completionProvider.triggerCharacters) do
			chars[ch] = true
		end
	end

	-- Make builtin completion feel responsive during normal identifier typing.
	for ch in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"):gmatch(".") do
		chars[ch] = true
	end

	local merged = {}
	for ch, _ in pairs(chars) do
		table.insert(merged, ch)
	end

	return merged
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
			vim.lsp.completion.enable(true, client.id, ev.buf, {
				autotrigger = true,
				triggerCharacters = completion_trigger_chars(client),
			})
		end
	end,
})
