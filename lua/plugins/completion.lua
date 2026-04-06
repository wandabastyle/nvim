require("blink.cmp").setup({
	sources = {
		default = { "lsp", "path", "buffer", "snippets" },
	},
	snippets = {
		preset = "default",
	},
	keymap = {
		preset = "default",
		["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
		["<CR>"] = { "accept", "fallback" },
		["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
		["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
	},
})
