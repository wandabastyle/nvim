--Set leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Relative line numbers
vim.o.relativenumber = true
vim.o.number = true

-- Case insensitive search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Sync clipboards
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Raise dialog if unsaved buffer
vim.o.confirm = true

-- Snappy escape
vim.o.ttimeoutlen = 1

-- Diagnostics
vim.diagnostic.config({
	severity_sort = true,
	update_in_insert = false,
	jump = { source = 'if_many' },
	on_jump = { float = true },
})

-- Show diagnostics
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostics' })

-- Easily move between windows
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Highlight yanks
vim.api.nvim_create_autocmd('TextYankPost', {
	group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
	callback = function() vim.highlight.on_yank() end
})
