require("gitsigns").setup()

require("mini.pick").setup()

require("oil").setup({
	view_options = {
		show_hidden = true,
	},
})

vim.cmd("colorscheme tokyonight-moon")
require("lualine").setup()
