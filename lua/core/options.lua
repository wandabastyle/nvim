local opt = vim.opt

opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true

opt.clipboard = "unnamedplus"
opt.swapfile = false
opt.wrap = false
opt.scrolloff = 6

opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Completion UX defaults used by built-in and plugin completion menus.
opt.completeopt = { "menu", "menuone", "noselect" }
opt.updatetime = 250
opt.timeoutlen = 300
