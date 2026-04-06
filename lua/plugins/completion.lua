require("blink.cmp").setup({
	sources = {
		default = { "lsp", "path", "buffer", "snippets" },
	},
	snippets = {
		expand = function(snippet)
			vim.snippet.expand(snippet)
		end,
	},
	keymap = {
		preset = "default",
		["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
		["<CR>"] = { "accept", "fallback" },
		["<Tab>"] = {
			function(cmp)
				if cmp.is_visible() then
					return cmp.select_next()
				end
				if vim.snippet.active({ direction = 1 }) then
					return vim.snippet.jump(1)
				end
			end,
			"fallback",
		},
		["<S-Tab>"] = {
			function(cmp)
				if cmp.is_visible() then
					return cmp.select_prev()
				end
				if vim.snippet.active({ direction = -1 }) then
					return vim.snippet.jump(-1)
				end
			end,
			"fallback",
		},
	},
})
