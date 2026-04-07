local conform = require("conform")

conform.setup({
	notify_on_error = true,
	log_level = vim.log.levels.WARN,
	formatters_by_ft = {
		python = { "ruff_organize_imports", "ruff_format" },
		rust = { "rustfmt" },
		lua = { "stylua" },
		nix = { "nixfmt" },
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
	},
	formatters = {
		ruff_format = {
			command = "ruff",
			args = { "format", "--stdin-filename", "$FILENAME", "-" },
		},
	},
})

local function format_err_message(format_err)
	if type(format_err) == "table" then
		return format_err.message or format_err.err or vim.inspect(format_err)
	end
	return tostring(format_err)
end

local function format_with_notify()
	local ok, err = pcall(function()
		conform.format({
			async = false,
			lsp_format = "fallback",
			quiet = false,
		}, function(format_err)
			if format_err then
				vim.notify(
					("Formatting failed: %s"):format(format_err_message(format_err)),
					vim.log.levels.ERROR,
					{ title = "Conform" }
				)
			end
		end)
	end)

	if not ok then
		vim.notify(
			("Formatting failed: %s"):format(format_err_message(err)),
			vim.log.levels.ERROR,
			{ title = "Conform" }
		)
	end
end

local format_on_save_filetypes = {
	python = true,
	rust = true,
	lua = true,
	nix = true,
	javascript = true,
	javascriptreact = true,
	typescript = true,
	typescriptreact = true,
}

local format_on_save = vim.api.nvim_create_augroup("conform_format_on_save", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = format_on_save,
	callback = function(args)
		if not format_on_save_filetypes[vim.bo[args.buf].filetype] then
			return
		end

		local ok, err = pcall(conform.format, {
			bufnr = args.buf,
			async = false,
			lsp_format = "fallback",
			quiet = true,
		})

		if not ok then
			vim.notify(("Format on save failed: %s"):format(format_err_message(err)), vim.log.levels.WARN, {
				title = "Conform",
			})
		end
	end,
})

vim.keymap.set("n", "<leader>lf", format_with_notify, { desc = "Format buffer" })
