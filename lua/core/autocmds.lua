local group = vim.api.nvim_create_augroup("user_config", { clear = true })

-- Highlight yanked text briefly.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 140 })
  end,
})
