require("gitsigns").setup()

require("mini.pick").setup()

local wk = require("which-key")
wk.setup({})
wk.add({
	{ "<leader>f", group = "Find" },
	{ "<leader>r", group = "Run" },
	{ "<leader>l", group = "LSP" },
	{ "<leader>g", group = "Git" },
})

require("oil").setup({
	view_options = {
		show_hidden = true,
	},
})

vim.cmd("colorscheme tokyonight-moon")
require("lualine").setup()
