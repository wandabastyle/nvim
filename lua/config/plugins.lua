vim.pack.add({
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/echasnovski/mini.pairs" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require("gitsigns").setup()

require("mini.pick").setup()
local pick = require("mini.pick").builtin
vim.keymap.set("n", "<leader>ff", pick.files)
vim.keymap.set("n", "<leader>fb", pick.buffers)
vim.keymap.set("n", "<leader>fg", pick.grep)
vim.keymap.set("n", "<leader>h", pick.help)

require("mini.pairs").setup()

require("oil").setup({
	view_options = {
		show_hidden = true,
	},
})
vim.keymap.set("n", "<leader>e", ":Oil<CR>")
