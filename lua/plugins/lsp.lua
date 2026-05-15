local servers = { "lua_ls", "rust_analyzer", "ty", "ruff", "ts_ls", "svelte" }

local function setup_lsp()
	local capabilities = require("blink.cmp").get_lsp_capabilities()

	vim.lsp.config["lua_ls"] = {
		capabilities = capabilities,
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				workspace = {
					checkThirdParty = false,
					library = vim.api.nvim_get_runtime_file("", true),
				},
				telemetry = { enable = false },
			},
		},
	}

	vim.lsp.config["rust_analyzer"] = {
		capabilities = capabilities,
	}

	vim.lsp.config["ty"] = {
		capabilities = capabilities,
	}

	vim.lsp.config["ruff"] = {
		capabilities = capabilities,
	}

	vim.lsp.config["ts_ls"] = {
		capabilities = capabilities,
	}

	vim.lsp.config["svelte"] = {
		capabilities = capabilities,
	}

	vim.lsp.enable(servers)

	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client then
				return
			end

			local opts = { buffer = ev.buf }

			vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
			vim.keymap.set(
				"n",
				"gd",
				vim.lsp.buf.definition,
				vim.tbl_extend("force", opts, { desc = "Go to definition" })
			)
			vim.keymap.set(
				"n",
				"gr",
				vim.lsp.buf.references,
				vim.tbl_extend("force", opts, { desc = "Find references" })
			)
			vim.keymap.set(
				"n",
				"<leader>lr",
				vim.lsp.buf.rename,
				vim.tbl_extend("force", opts, { desc = "Rename symbol" })
			)
			vim.keymap.set(
				"n",
				"<leader>la",
				vim.lsp.buf.code_action,
				vim.tbl_extend("force", opts, { desc = "Code action" })
			)
			vim.keymap.set(
				"n",
				"<leader>ld",
				vim.diagnostic.open_float,
				vim.tbl_extend("force", opts, { desc = "Line diagnostics" })
			)
			vim.keymap.set("n", "<leader>ll", function()
				vim.diagnostic.setloclist({ open = true })
			end, vim.tbl_extend("force", opts, { desc = "Diagnostics list" }))
			vim.keymap.set("n", "<leader>ls", function()
				vim.ui.input({ prompt = "Workspace symbol: " }, function(input)
					if not input then
						return
					end

					local query = vim.trim(input)
					if query == "" then
						return
					end

					vim.lsp.buf.workspace_symbol(query)
				end)
			end, vim.tbl_extend("force", opts, { desc = "Workspace symbols" }))
			vim.keymap.set("n", "<leader>lp", function()
				vim.diagnostic.jump({ count = -1 })
			end, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
			vim.keymap.set("n", "<leader>ln", function()
				vim.diagnostic.jump({ count = 1 })
			end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))

			if
				client:supports_method("textDocument/semanticTokens/full")
				or client:supports_method("textDocument/semanticTokens/range")
			then
				vim.lsp.semantic_tokens.enable(true, { bufnr = ev.buf })
			end
		end,
	})
end

return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = {
			{ "<leader>mm", "<cmd>Mason<CR>", desc = "Mason registry" },
		},
		opts = {
			ui = {
				border = "rounded",
			},
		},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		opts = {
			ensure_installed = servers,
			automatic_enable = false,
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"stylua",
				"ruff",
				"typescript-language-server",
				"svelte-language-server",
				"prettier",
				"shfmt",
				"shellcheck",
			},
			auto_update = false,
			run_on_start = false,
		},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"Saghen/blink.cmp",
			"williamboman/mason-lspconfig.nvim",
		},
		config = setup_lsp,
	},
}
