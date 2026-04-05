# Neovim config (fresh rebuild for 0.11.x)

A clean, minimal Neovim setup rebuilt from scratch for **Neovim 0.11.x stable**.

## Goals

- Simple structure and readable Lua
- Lazy.nvim plugin management
- Lightweight editing workflow (not IDE-heavy)
- Good defaults for: **Lua, Nix, Rust, Python, TypeScript/JavaScript**
- Keep familiar keymap spirit (leader, picker, Oil, LSP navigation, run/build terminal)

## Target version

- **Neovim:** `0.11.x` stable
- **Plugin manager:** [`lazy.nvim`](https://github.com/folke/lazy.nvim)

## Directory structure

```text
.
├── init.lua
├── lua
│   ├── config
│   │   ├── autocmds.lua
│   │   ├── commands.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   ├── plugins
│   │   ├── editing.lua
│   │   ├── git.lua
│   │   ├── lsp.lua
│   │   ├── navigation.lua
│   │   ├── treesitter.lua
│   │   └── ui.lua
│   └── util
│       └── project_terminal.lua
└── README.md
```

## Installed plugins / features

### UI

- `folke/tokyonight.nvim` (using **tokyonight-moon**)
- `nvim-lualine/lualine.nvim`
- `nvim-tree/nvim-web-devicons`

### Navigation / files

- `nvim-telescope/telescope.nvim`
- `stevearc/oil.nvim`

### Git / editing

- `lewis6991/gitsigns.nvim`
- `nvim-treesitter/nvim-treesitter`
- `windwp/nvim-autopairs`
- `ethanholz/nvim-lastplace`

### LSP

- `neovim/nvim-lspconfig`
- `williamboman/mason.nvim`
- `williamboman/mason-lspconfig.nvim`

## Language setup

Enabled LSP servers:

- `lua_ls` (Lua, including Neovim runtime awareness)
- `nixd`
- `rust_analyzer`
- `pyright`
- `ts_ls` (TypeScript + JavaScript)

Completion uses Neovim's built-in LSP completion (`vim.lsp.completion`) on attach.

## External dependencies (install on your system)

### Required runtime tools

- `git`
- `curl` (or a package manager capable of fetching plugins)
- a Nerd Font (recommended for icons)

### For Telescope grep

- `ripgrep` (`rg`)

### LSP servers and language tools

Mason can install configured servers for you. You may still want language toolchains installed:

- **Lua:** `lua-language-server` (Mason)
- **Nix:** `nixd` + `nixfmt`
- **Rust:** `rust-analyzer` + Rust toolchain (`cargo`, `rustc`)
- **Python:** `pyright` (Mason) + Python interpreter
- **TypeScript/JavaScript:** `typescript-language-server` (Mason) and `typescript`

If a Mason package fails on your distro, install that tool with your system package manager and keep the same binary name.

## First start

1. Clone repo into `~/.config/nvim`.
2. Open Neovim.
3. Wait for lazy.nvim bootstrap.
4. Run:
   - `:Lazy sync`
   - `:Mason` (confirm servers are installed)

## Updating plugins

- `:Lazy sync` to update/install
- `:Lazy clean` to remove unused plugins
- `:Lazy health` for diagnostics

## Keymap overview

Leader key: **Space**

### Core

- `<leader>w` save
- `<leader>q` quit
- `<leader>y` yank to system clipboard
- `<leader>d` delete to system clipboard
- `<Esc>` clear search highlight

### Picker / explorer

- `<leader>ff` find files
- `<leader>fb` buffers
- `<leader>fg` live grep
- `<leader>fh` help tags
- `<leader>e` Oil file explorer

### Diagnostics + LSP

- `[d` previous diagnostic
- `]d` next diagnostic
- `<leader>ld` line diagnostic float
- `K` hover
- `gd` definition
- `gr` references
- `<leader>lr` rename
- `<leader>la` code action
- `<leader>lf` format
- `<C-Space>` trigger completion (insert mode)

### Run/build terminal workflow

- `:ProjectRun` run current project/file in reusable bottom terminal split
- `:ProjectBuild` build current project/file in reusable bottom terminal split
- `<leader>rr` run
- `<leader>rb` build
- `<leader>rt` focus terminal
- `<leader>rc` close terminal

Current defaults:

- Rust project (`Cargo.toml`):
  - run: `cargo run`
  - build: `cargo build`
- Python file:
  - run: `python <current-file>`
  - build: `python -m compileall .`
- JS/TS project (`package.json`):
  - run: `npm run dev`
  - build: `npm run build`

## Notes on Mason

- Mason manages editor-side LSP binaries for convenience.
- It does **not** replace language runtimes (Node, Python, Rust toolchains, etc.).
- If you prefer fully system-managed tooling, you can disable Mason and still use `nvim-lspconfig`.
