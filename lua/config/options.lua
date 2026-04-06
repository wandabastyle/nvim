local undodir = vim.fn.expand("~/.vim/undodir")
if
	vim.fn.isdirectory(undodir) == 0
then
	vim.fn.mkdir(undodir, "p")
end

vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.undofile = true
vim.o.undodir = undodir
vim.o.clipboard = "unnamedplus"
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.winborder = "rounded"

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.smartindent = true
vim.o.autoindent = true
vim.o.wrap = false
vim.o.scrolloff = 5

vim.o.completeopt = "menu,menuone,noinsert,noselect"
vim.cmd("set completeopt+=noselect")
