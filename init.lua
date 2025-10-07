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
	{ src = "https://github.com/echasnovski/mini.pairs" },
	{ src = "https://github.com/stevearc/oil.nvim" },
})

require "mini.pick".setup()
local pick = require("mini.pick").builtin
vim.keymap.set('n', '<leader>ff', pick.files)
vim.keymap.set('n', '<leader>fb', pick.buffers)
vim.keymap.set('n', '<leader>fg', pick.grep)
vim.keymap.set('n', '<leader>h', pick.help)

require "mini.pairs".setup()

require "oil".setup({
	view_options = {
		show_hidden = true,
	},
})
vim.keymap.set('n', '<leader>e', ":Oil<CR>")

vim.lsp.enable({ "lua_ls" })
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.o.completeopt = "menu,menuone,noinsert,noselect"

for k, v in pairs({ ["<Tab>"] = { "<C-n>", "<Tab>" }, ["<S-Tab>"] = { "<C-p>", "<S-Tab>" }, ["<CR>"] = { "<C-y>", "<CR>" } }) do
	vim.keymap.set("i", k, function() return vim.fn.pumvisible() == 1 and v[1] or v[2] end, { expr = true, silent = true })
end

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})
vim.cmd("set completeopt+=noselect")

vim.cmd("colorscheme tokyonight-moon")

require "lualine".setup()
