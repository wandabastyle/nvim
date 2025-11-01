vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.swapfile = false
vim.o.clipboard = "unnamedplus"
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.winborder = "rounded"

vim.g.mapleader = " "

vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y<CR>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>d', '"+d<CR>')

vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })


vim.keymap.set("i", "yy", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.wrap = false

vim.pack.add({
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/windwp/nvim-autopairs" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require "gitsigns".setup()

require "mini.pick".setup()
local pick = require("mini.pick").builtin
vim.keymap.set('n', '<leader>ff', pick.files)
vim.keymap.set('n', '<leader>fb', pick.buffers)
vim.keymap.set('n', '<leader>fg', pick.grep)
vim.keymap.set('n', '<leader>h', pick.help)

require "nvim-autopairs".setup({
	map_cr = true,
	check_ts = true,
})

require "nvim-treesitter.configs".setup({
	highlight = { enable = true },
	indent = { enable = true },
})

require "oil".setup({
	view_options = {
		show_hidden = true,
	},
})
vim.keymap.set('n', '<leader>e', ":Oil<CR>")

vim.lsp.enable({ "lua_ls", "nil", "kdl-lsp" })

vim.lsp.config["nil"] = {
	cmd = { "nil" },
	filetypes = { "nix" },
	single_file_support = true,
	settings = {
		["nil"] = {
			formatting = { command = { "nixfmt" } },
		},
	},
}

vim.lsp.config["kdl-lsp"] = {
	cmd = { "kdl-lsp" },
	filetypes = { "kdl" },
	root_markers = { ".git" },
	single_file_support = true,
}

vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.o.completeopt = "menu,menuone,noinsert,noselect"

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		local buf = ev.buf
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		-- enable LSP-powered completion
		if client and client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
		end

		-- small helper for buffer-local maps
		local map = function(mode, lhs, rhs)
			vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true })
		end

		-- LSP maps
		if client then
			if client:supports_method('textDocument/definition') then
				map("n", "gd", vim.lsp.buf.definition)
			end
			if client:supports_method('textDocument/hover') then
				map("n", "K", vim.lsp.buf.hover)
			end
			if client:supports_method('textDocument/rename') then
				map("n", "<leader>rn", vim.lsp.buf.rename)
			end
			if client:supports_method('textDocument/codeAction') then
				map("n", "<leader>ca", vim.lsp.buf.code_action)
			end
		end
		-- Diagnostics navigation doesn't depend on server capabilities
		map("n", "[d", vim.diagnostic.goto_prev)
		map("n", "]d", vim.diagnostic.goto_next)
		map("n", "gl", vim.diagnostic.open_float) -- tooltip with diagnostics (optional)
	end
})
vim.cmd("set completeopt+=noselect")

vim.cmd("colorscheme tokyonight-moon")

require "lualine".setup()
