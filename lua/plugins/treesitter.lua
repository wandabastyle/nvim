require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"rust",
		"python",
		"lua",
		"bash",
		"json",
		"toml",
		"yaml",
		"markdown",
		"markdown_inline",
		"vim",
		"vimdoc",
		"query",
		"gitignore",
		"gitcommit",
		"diff",
	},

	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},

	indent = {
		enable = true,
		disable = { "python" },
	},
})
