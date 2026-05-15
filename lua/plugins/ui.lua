return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd("colorscheme tokyonight-moon")
		end,
	},
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = true,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = true,
	},
	{
		"folke/snacks.nvim",
		priority = 900,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			input = { enabled = true },
			picker = { enabled = true },
			quickfile = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
	},
	{
		"stevearc/oil.nvim",
		lazy = false,
		keys = {
			{ "<leader>e", "<cmd>Oil<CR>", desc = "Open explorer" },
		},
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			default_file_explorer = true,
			view_options = {
				show_hidden = true,
			},
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({})
			wk.add({
				{ "<leader>f", group = "Find" },
				{ "<leader>r", group = "Run" },
				{ "<leader>l", group = "LSP" },
				{ "<leader>g", group = "Git" },
				{ "<leader>m", group = "Mason" },
				{ "<leader>x", group = "Trouble" },
				{ "<leader>t", group = "TODO" },
			})
		end,
	},
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics" },
			{ "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
			{ "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
			{ "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
			{ "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols" },
		},
		opts = {},
	},
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
	},
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>tt", "<cmd>TodoTrouble<CR>", desc = "TODO list" },
			{ "<leader>tq", "<cmd>TodoQuickFix<CR>", desc = "TODO quickfix" },
			{
				"<leader>tn",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next TODO",
			},
			{
				"<leader>tp",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous TODO",
			},
		},
		opts = {},
	},
	{
		"rcarriga/nvim-notify",
		lazy = false,
		config = function()
			require("notify").setup({
				timeout = 3000,
				background_colour = "#1f2335",
			})
			vim.notify = require("notify")
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},
	},
}
