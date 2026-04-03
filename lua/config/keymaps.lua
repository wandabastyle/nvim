vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y<CR>')
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"+d<CR>')

vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })

vim.keymap.set("i", "yy", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("i", "<C-Space>", function()
	vim.lsp.completion.get()
end, { silent = true, desc = "Trigger LSP completion" })

for k, v in pairs({ ["<Tab>"] = { "<C-n>", "<Tab>" }, ["<S-Tab>"] = { "<C-p>", "<S-Tab>" }, ["<CR>"] = { "<C-y>", "<CR>" } }) do
	vim.keymap.set("i", k, function()
		return vim.fn.pumvisible() == 1 and v[1] or v[2]
	end, { expr = true, silent = true })
end
