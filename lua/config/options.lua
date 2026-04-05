local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 5
opt.wrap = false
opt.splitbelow = true
opt.splitright = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true

opt.clipboard = "unnamedplus"
opt.swapfile = false
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 200

opt.completeopt = { "menu", "menuone", "noinsert", "noselect", "popup" }

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded" },
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = false,
})
