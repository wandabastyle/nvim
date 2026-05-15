vim.g.mapleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.options")
require("config.diagnostics")
require("plugins")
require("config.highlights")
require("features.project_terminal").setup()
require("config.commands")
require("config.keymaps")
require("config.autocmds")
require("config.commit_ai").setup()
