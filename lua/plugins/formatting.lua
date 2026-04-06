require("conform").setup({
	formatters_by_ft = {
		python = { "ruff_format" },
		rust = { "rustfmt" },
		lua = { "stylua" },
		nix = { "nixfmt" },
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
	},
})

vim.keymap.set("n", "<leader>lf", function()
	require("conform").format({
		async = true,
		lsp_format = "fallback",
	})
end, { desc = "Format buffer" })
