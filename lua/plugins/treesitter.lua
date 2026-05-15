local parsers = {
	"rust",
	"python",
	"lua",
	"javascript",
	"typescript",
	"tsx",
	"svelte",
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
}

local filetypes = {
	"rust",
	"python",
	"lua",
	"javascript",
	"typescript",
	"typescriptreact",
	"svelte",
	"sh",
	"bash",
	"json",
	"toml",
	"yaml",
	"markdown",
	"vim",
	"vimdoc",
	"query",
	"gitignore",
	"gitcommit",
	"diff",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local treesitter = require("nvim-treesitter")

			treesitter.setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
				pattern = filetypes,
				callback = function(args)
					local ok = pcall(vim.treesitter.start, args.buf)
					if not ok then
						return
					end

					vim.wo.foldmethod = "expr"
					vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

					if vim.bo[args.buf].filetype ~= "python" then
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},
}
