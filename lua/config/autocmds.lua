local python_indent = vim.api.nvim_create_augroup("python_indent", { clear = true })

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
