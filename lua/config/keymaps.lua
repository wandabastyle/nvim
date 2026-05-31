local project_terminal = require("features.project_terminal")

local function snacks_pick(name)
	return function()
		require("snacks").picker[name]()
	end
end

vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y<CR>', { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"+d<CR>', { desc = "Delete to clipboard" })

vim.keymap.set("n", "<leader>lk", function()
	local wk = require("which-key")
	wk.show({ global = false })
end, { desc = "Buffer keymaps" })

vim.keymap.set("n", "<leader>rr", "<cmd>ProjectRun<CR>", { silent = true, desc = "Run project/current file" })
vim.keymap.set("n", "<leader>rb", "<cmd>ProjectBuild<CR>", { silent = true, desc = "Build project" })
vim.keymap.set("n", "<leader>rc", project_terminal.close, { silent = true, desc = "Close project terminal" })
vim.keymap.set("n", "<leader>rt", project_terminal.focus, { silent = true, desc = "Focus project terminal" })

vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true, desc = "Focus left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true, desc = "Focus lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true, desc = "Focus upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true, desc = "Focus right window" })

vim.keymap.set("i", "yy", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

vim.keymap.set("n", "<leader>ff", snacks_pick("files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>fb", snacks_pick("buffers"), { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fg", snacks_pick("grep"), { desc = "Live grep" })
vim.keymap.set("n", "<leader>fh", snacks_pick("help"), { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", snacks_pick("recent"), { desc = "Recent files" })
vim.keymap.set("n", "<leader>fd", snacks_pick("diagnostics"), { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>fc", function()
	require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find config files" })

vim.keymap.set("n", "<Esc>", "<Esc>:nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })

-- Spell checking
vim.keymap.set("n", "<leader>ts", function()
	vim.wo.spell = not vim.wo.spell
	local status = vim.wo.spell and "enabled" or "disabled"
	vim.notify("Spell checking " .. status, vim.log.levels.INFO)
end, { desc = "Toggle spell checking" })

-- Navigate to next/previous misspelled word
vim.keymap.set("n", "]s", "]s", { desc = "Next misspelled word" })
vim.keymap.set("n", "[s", "[s", { desc = "Previous misspelled word" })

-- Show spelling suggestions for word under cursor
vim.keymap.set("n", "z=", "z=", { desc = "Show spelling suggestions" })

-- Add word to spell file
vim.keymap.set("n", "zg", "zg", { desc = "Add word to spell file" })

-- Mark word as wrong
vim.keymap.set("n", "zw", "zw", { desc = "Mark word as wrong" })
