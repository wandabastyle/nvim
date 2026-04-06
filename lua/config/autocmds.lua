local ollama = require("config.ollama")

local python_indent = vim.api.nvim_create_augroup("python_indent", { clear = true })
local ollama_lifecycle = vim.api.nvim_create_augroup("ollama_lifecycle", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = python_indent,
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = ollama_lifecycle,
  callback = function()
    ollama.on_vim_enter()
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = ollama_lifecycle,
  callback = function()
    ollama.on_vim_leave_pre()
  end,
})
