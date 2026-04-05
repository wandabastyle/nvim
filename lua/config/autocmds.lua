local group = vim.api.nvim_create_augroup("core_autocmds", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
  desc = "Briefly highlight yanked text",
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
  desc = "Python uses 4-space indentation",
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local bufnr = args.buf
    local opts = { buffer = bufnr }

    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover docs" }))
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
    vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
    vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
    vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
    vim.keymap.set("n", "<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
      vim.keymap.set("i", "<C-Space>", function()
        vim.lsp.completion.get()
      end, vim.tbl_extend("force", opts, { desc = "Trigger completion" }))
    end
  end,
  desc = "LSP keymaps and built-in completion",
})
