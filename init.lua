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

local project_runner = { buf = nil, win = nil }

local function find_project_root(markers, startpath)
	local found = vim.fs.find(markers, { upward = true, path = startpath, stop = vim.uv.os_homedir() })
	if #found == 0 then
		return nil
	end
	return vim.fs.dirname(found[1])
end

local function project_command(mode)
	local file = vim.api.nvim_buf_get_name(0)
	local from = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
	local root = find_project_root({ "Cargo.toml" }, from)

	if root then
		return mode == "build" and "cargo build" or "cargo run", root
	end

	if mode == "build" then
		return nil, nil, "No supported build target found for this project"
	end

	if file ~= "" and vim.bo.filetype == "python" then
		return ("python %s"):format(vim.fn.shellescape(file)), vim.fn.getcwd()
	end

	return nil, nil, "No supported project type found (Rust/Cargo or Python file)"
end

local function run_in_project_terminal(mode)
	local cmd, cwd, err = project_command(mode)
	if not cmd then
		vim.notify(err, vim.log.levels.WARN)
		return
	end

	if project_runner.buf and vim.api.nvim_buf_is_valid(project_runner.buf) then
		local job = vim.b[project_runner.buf].terminal_job_id
		if not project_runner.win or not vim.api.nvim_win_is_valid(project_runner.win) then
			vim.cmd("botright split")
			vim.cmd("resize 12")
			project_runner.win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(project_runner.win, project_runner.buf)
		else
			vim.api.nvim_set_current_win(project_runner.win)
		end

		if job then
			vim.fn.chansend(job, ("cd %s && %s\n"):format(vim.fn.shellescape(cwd), cmd))
		end
		vim.cmd("startinsert")
		return
	end

	vim.cmd("botright split")
	vim.cmd("resize 12")
	vim.cmd("terminal")
	project_runner.win = vim.api.nvim_get_current_win()
	project_runner.buf = vim.api.nvim_get_current_buf()
	local job = vim.b[project_runner.buf].terminal_job_id
	vim.fn.chansend(job, ("cd %s && %s\n"):format(vim.fn.shellescape(cwd), cmd))
	vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = project_runner.buf, silent = true, desc = "Close project terminal" })
	vim.keymap.set("t", "<C-q>", [[<C-\><C-n><cmd>close<CR>]], { buffer = project_runner.buf, silent = true, desc = "Close project terminal" })
	vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("ProjectRun", function() run_in_project_terminal("run") end, {})
vim.api.nvim_create_user_command("ProjectBuild", function() run_in_project_terminal("build") end, {})
vim.keymap.set("n", "<leader>rr", "<cmd>ProjectRun<CR>", { silent = true, desc = "Run project/current file" })
vim.keymap.set("n", "<leader>rb", "<cmd>ProjectBuild<CR>", { silent = true, desc = "Build project" })

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
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require "gitsigns".setup()

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

vim.lsp.enable({ "lua_ls", "nixd", "rust_analyzer", "pylsp" })
vim.lsp.config["nixd"] = {
	settings = {
		nixd = {
			formatting = { command = { "nixfmt" } },
			nixpkgs = { expr = "import <nixpkgs> {}" },
			options = { nixos = { expr = "(import <nixpkgs/nixos> { configuration = {}; }).options" } },
		},
	},
}
vim.lsp.config["pylsp"] = {
	settings = {
		pylsp = {
			plugins = {
				pycodestyle = { enabled = false },
				mccabe = { enabled = false },
				pyflakes = { enabled = false },
				autopep8 = { enabled = false },
				yapf = { enabled = false },
				black = { enabled = true },
				pylsp_mypy = { enabled = false },
			},
		},
	},
}

vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.o.completeopt = "menu,menuone,noinsert,noselect"
vim.keymap.set("i", "<C-Space>", function() vim.lsp.completion.get() end, { silent = true, desc = "Trigger LSP completion" })

for k, v in pairs({ ["<Tab>"] = { "<C-n>", "<Tab>" }, ["<S-Tab>"] = { "<C-p>", "<S-Tab>" }, ["<CR>"] = { "<C-y>", "<CR>" } }) do
	vim.keymap.set("i", k, function() return vim.fn.pumvisible() == 1 and v[1] or v[2] end, { expr = true, silent = true })
end

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		local opts = { buffer = ev.buf }

		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
		vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts)
		vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

		if client:supports_method('textDocument/completion') then
			local printable_ascii = {}
			for i = 32, 126 do
				table.insert(printable_ascii, string.char(i))
			end
			-- Some servers only auto-trigger completion on specific characters. Expanding
			-- triggerCharacters to printable ASCII helps identifier typing, but may be slower.
			client.server_capabilities.completionProvider = client.server_capabilities.completionProvider or {}
			client.server_capabilities.completionProvider.triggerCharacters = printable_ascii
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})
vim.cmd("set completeopt+=noselect")

vim.cmd("colorscheme tokyonight-moon")

require "lualine".setup()
