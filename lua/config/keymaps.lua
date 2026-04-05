local pick = require("mini.pick").builtin
local project_terminal = require("features.project_terminal")

vim.keymap.set("n", "<leader>w", ":write<CR>")
vim.keymap.set("n", "<leader>q", ":quit<CR>")
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y<CR>')
vim.keymap.set({ "n", "v", "x" }, "<leader>d", '"+d<CR>')

vim.keymap.set("n", "<leader>rr", "<cmd>ProjectRun<CR>", { silent = true, desc = "Run project/current file" })
vim.keymap.set("n", "<leader>rb", "<cmd>ProjectBuild<CR>", { silent = true, desc = "Build project" })
vim.keymap.set("n", "<leader>rc", project_terminal.close, { silent = true, desc = "Close project terminal" })
vim.keymap.set("n", "<leader>rt", project_terminal.focus, { silent = true, desc = "Focus project terminal" })

vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })

vim.keymap.set("i", "yy", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

vim.keymap.set("n", "<leader>ff", pick.files)
vim.keymap.set("n", "<leader>fb", pick.buffers)
vim.keymap.set("n", "<leader>fg", pick.grep)
vim.keymap.set("n", "<leader>h", pick.help)

vim.keymap.set("n", "<leader>e", ":Oil<CR>")

vim.keymap.set("n", "<Esc>", "<Esc>:nohlsearch<CR>", { silent = true })
