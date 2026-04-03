vim.g.mapleader = " "

require("config.options")
require("plugins")
require("plugins.ui")
require("plugins.editing")
require("plugins.lsp")
require("features.project_terminal").setup()
require("config.commands")
require("config.keymaps")
require("config.autocmds")
