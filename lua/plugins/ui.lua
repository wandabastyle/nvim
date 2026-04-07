require("gitsigns").setup()

require("mini.pick").setup()

require("notify").setup({
	timeout = 3000,
	background_colour = "#1f2335",
})
vim.notify = require("notify")

require("noice").setup({
	lsp = {
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
	},
	presets = {
		bottom_search = true,
		command_palette = true,
		long_message_to_split = true,
	},
})

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
