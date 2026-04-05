local map = vim.keymap.set
local project_terminal = require("features.project_terminal")
local commit_ai = require("features.commit_ai")
local telescope = require("telescope.builtin")

-- Preserve existing muscle-memory mappings.
map("n", "w", "<cmd>write<CR>", { silent = true, desc = "Write buffer" })
map("n", "q", "<cmd>quit<CR>", { silent = true, desc = "Quit window" })

map({ "n", "x" }, "y", '"+y', { desc = "Yank to system clipboard" })
map({ "n", "x" }, "d", '"+d', { desc = "Delete to system clipboard" })

map("n", "rr", "<cmd>ProjectRun<CR>", { silent = true, desc = "Project run" })
map("n", "rb", "<cmd>ProjectBuild<CR>", { silent = true, desc = "Project build" })
map("n", "rc", project_terminal.close, { silent = true, desc = "Close project terminal" })
map("n", "rt", project_terminal.focus, { silent = true, desc = "Focus project terminal" })

map("n", "ff", telescope.find_files, { desc = "Find files" })
map("n", "fb", telescope.buffers, { desc = "Find buffers" })
map("n", "fg", telescope.live_grep, { desc = "Live grep" })
map("n", "h", telescope.help_tags, { desc = "Help tags" })

map("n", "e", "<cmd>Oil<CR>", { silent = true, desc = "File explorer" })
map("i", "yy", "<Esc>", { silent = true, desc = "Exit insert mode" })
map("n", "gw", commit_ai.save_and_commit, {
  silent = true,
  desc = "Save and git commit with AI message",
})

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true, desc = "Clear search" })
