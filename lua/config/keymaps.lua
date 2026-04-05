local map = vim.keymap.set
local terminal = require("util.project_terminal")

-- quick save / quit
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })

-- clipboard workflow
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map({ "n", "v" }, "<leader>d", '"+d', { desc = "Delete to system clipboard" })

-- quick movement and insert escape habit
map("n", "<C-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
map("n", "<C-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
map("i", "yy", "<Esc>", { desc = "Leave insert mode" })

-- diagnostics
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })

-- telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })

-- file explorer
map("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Open parent directory" })

-- terminal run/build workflow
map("n", "<leader>rr", function()
  terminal.run("run")
end, { desc = "Run project/file" })
map("n", "<leader>rb", function()
  terminal.run("build")
end, { desc = "Build project" })
map("n", "<leader>rt", terminal.focus, { desc = "Focus run terminal" })
map("n", "<leader>rc", terminal.close, { desc = "Close run terminal" })
