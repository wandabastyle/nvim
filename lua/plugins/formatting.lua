require("conform").setup({
	notify_on_error = true,
	log_level = vim.log.levels.DEBUG,
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

local function format_with_notify()
	local function format_err_message(format_err)
		if type(format_err) == "table" then
			return format_err.message or format_err.err or vim.inspect(format_err)
		end
		return tostring(format_err)
	end

	local ok, err = pcall(function()
		require("conform").format({
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
		vim.notify(("Formatting failed: %s"):format(format_err_message(err)), vim.log.levels.ERROR, { title = "Conform" })
	end
end

vim.keymap.set("n", "<leader>lf", format_with_notify, { desc = "Format buffer" })
