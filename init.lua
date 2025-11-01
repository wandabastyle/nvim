-- Neovim 0.11 + lazy.nvim setup
-- If you are migrating from vim.pack, this bootstraps lazy.nvim and mirrors your previous plugins/config.

-- =====================
-- Options & Keymaps
-- =====================
vim.g.mapleader = " "

vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.swapfile = false
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
vim.o.completeopt = "menu,menuone,noinsert,noselect"

vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y<CR>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>d', '"+d<CR>')

vim.keymap.set("n", "<C-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })

vim.keymap.set("i", "yy", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- =====================
-- Bootstrap lazy.nvim
-- =====================
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) and not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- =====================
-- Plugins
-- =====================
require('lazy').setup({
  -- Colorscheme first, high priority
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    lazy = false,
    opts = {},
    config = function()
      vim.cmd('colorscheme tokyonight-moon')
    end,
  },

  -- Icons (used by several plugins)
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup()
    end,
  },

  -- LSP plugin present (not used for setup, but handy for extras)
  { 'neovim/nvim-lspconfig' },

  -- mini.pick (fuzzy picker)
  {
    'echasnovski/mini.pick',
    version = '*',
    config = function()
      require('mini.pick').setup()
      local pick = require('mini.pick').builtin
      vim.keymap.set('n', '<leader>ff', pick.files)
      vim.keymap.set('n', '<leader>fb', pick.buffers)
      vim.keymap.set('n', '<leader>fg', pick.grep)
      vim.keymap.set('n', '<leader>h',  pick.help)
    end,
  },

  -- Autopairs
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({
        map_cr = true,
        check_ts = true,
      })
    end,
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'lua', 'nix', 'kdl' },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
    end,
  },

  -- Oil (file explorer)
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup({
        view_options = { show_hidden = true },
      })
      vim.keymap.set('n', '<leader>e', ':Oil<CR>')
    end,
  },

  -- Git signs
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },
})

-- =====================
-- LSP configuration — plain tables + vim.lsp.start (Neovim 0.11)
-- =====================

-- Helper: find project root via nearest marker
local function root_with(markers)
  return function(path)
    local found = vim.fs.find(markers, { upward = true, path = path or vim.api.nvim_buf_get_name(0) })[1]
    return found and vim.fs.dirname(found) or vim.uv.cwd() or vim.loop.cwd()
  end
end

-- Client configs as plain tables (robust on 0.11.4)
local lua_cfg = {
  name = 'lua_ls',
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_dir = root_with({ '.luarc.json', '.luarc.jsonc', '.stylua.toml', '.git' }),
  settings = {
    Lua = {
      diagnostics = { globals = { 'vim' } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

local nil_cfg = {
  name = 'nil_ls',
  cmd = { 'nil' }, -- change to { 'nil_ls' } if that's your binary
  filetypes = { 'nix' },
  root_dir = root_with({ 'flake.nix', 'shell.nix', '.git' }),
  settings = { ['nil'] = { formatting = { command = { 'nixfmt' } } } },
}

local kdl_cfg = {
  name = 'kdl_ls',
  cmd = { 'kdl-lsp' },
  filetypes = { 'kdl' },
  root_dir = root_with({ '.git' }),
  single_file_support = true,
}

-- Start servers on demand by filetype (guard against duplicates)
local function ensure_started(config)
  -- Don’t start twice in the same buffer
  for _, c in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if c.name == config.name then return end
  end
  vim.lsp.start(config)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'lua',
  callback = function() ensure_started(lua_cfg) end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'nix',
  callback = function() ensure_started(nil_cfg) end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'kdl',
  callback = function() ensure_started(kdl_cfg) end,
})

-- Handy formatting mapping
vim.keymap.set('n', '<leader>lf', function()
  vim.lsp.buf.format({ async = false })
end)

-- Built-in LSP completion in 0.11 (autotrigger if server supports it)
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local buf = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if client and client.supports_method and client:supports_method('textDocument/completion') then
      if vim.lsp.completion and vim.lsp.completion.enable then
        vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
      end
    end

    local map = function(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true })
    end

    if client then
      if client.supports_method and client:supports_method('textDocument/definition') then
        map('n', 'gd', vim.lsp.buf.definition)
      end
      if client.supports_method and client:supports_method('textDocument/hover') then
        map('n', 'K', vim.lsp.buf.hover)
      end
      if client.supports_method and client:supports_method('textDocument/rename') then
        map('n', '<leader>rn', vim.lsp.buf.rename)
      end
      if client.supports_method and client:supports_method('textDocument/codeAction') then
        map('n', '<leader>ca', vim.lsp.buf.code_action)
      end
    end

    map('n', '[d', vim.diagnostic.goto_prev)
    map('n', ']d', vim.diagnostic.goto_next)
    map('n', 'gl', vim.diagnostic.open_float)
  end,
})

