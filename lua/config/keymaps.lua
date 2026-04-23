local pick = require("mini.pick").builtin
local project_terminal = require("features.project_terminal")
local wk = require("which-key")

vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y<CR>', { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"+d<CR>', { desc = "Delete to clipboard" })

vim.keymap.set("n", "<leader>?", function()
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

vim.keymap.set("n", "<leader>ff", pick.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fb", pick.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fg", pick.grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>h", pick.help, { desc = "Help tags" })

vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Open explorer" })

vim.keymap.set("n", "<Esc>", "<Esc>:nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })
