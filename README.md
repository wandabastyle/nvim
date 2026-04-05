# Neovim config (0.11 stable)

A clean Neovim rebuild focused on stable APIs and predictable behavior.

- **Neovim target**: `0.11.x` stable
- **Plugin manager**: `lazy.nvim`
- **Theme**: `tokyonight-moon`
- **Style**: minimal, readable, modular, easy to extend

---

## Requirements

- Neovim `0.11.x`
- `git`
- `curl` (optional, for many language/tool install flows)
- `python3` (for Python tooling and the commit AI helper)
- Language tools you care about (see [Language support](#language-support))

Optional but recommended:
- `ripgrep` for Telescope live grep (`fg` mapping)
- `fd` for faster Telescope file discovery

---

## Layout

```text
.
├── init.lua
├── lua
│   ├── core
│   │   ├── autocmds.lua
│   │   ├── commands.lua
│   │   ├── init.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   ├── features
│   │   ├── commit_ai.lua
│   │   └── project_terminal.lua
│   └── plugins
│       ├── editor.lua
│       ├── init.lua
│       ├── lsp.lua
│       ├── treesitter.lua
│       └── ui.lua
└── scripts
    └── git-commit-ai.py
```

---

## Plugin stack

### Core
- `folke/lazy.nvim` (plugin manager)

### UI / workflow
- `folke/tokyonight.nvim`
- `nvim-lualine/lualine.nvim`
- `nvim-tree/nvim-web-devicons`
- `lewis6991/gitsigns.nvim`
- `stevearc/oil.nvim` (file explorer)
- `nvim-telescope/telescope.nvim`
- `nvim-lua/plenary.nvim` (Telescope dependency)

### Editing
- `windwp/nvim-autopairs`
- `ethanholz/nvim-lastplace`

### Syntax / structure
- `nvim-treesitter/nvim-treesitter` (pinned to `master` for Neovim 0.11)

### LSP / completion
- `neovim/nvim-lspconfig`
- `williamboman/mason.nvim`
- `hrsh7th/nvim-cmp`
- `hrsh7th/cmp-nvim-lsp`
- `hrsh7th/cmp-buffer`
- `hrsh7th/cmp-path`
- `L3MON4D3/LuaSnip`
- `saadparwaiz1/cmp_luasnip`
- `rafamadriz/friendly-snippets`

---

## Language support

Configured as first-class defaults:
- Lua (`lua_ls`)
- Nix (`nixd`)
- Rust (`rust_analyzer`)
- Python (`pyright`)
- TypeScript / JavaScript (`ts_ls`)

Treesitter parsers are included for these and common related formats.

### LSP server/tool installation

Mason is enabled and configured to install:
- `lua-language-server`
- `nixd`
- `rust-analyzer`
- `pyright`
- `typescript-language-server`

Use:
- `:Mason` to view/install/uninstall servers manually
- `:checkhealth` to verify toolchain status

Note:
- Some servers require system binaries in addition to Mason packages.
- For TypeScript, ensure Node.js tooling is available in your environment.

---

## Core editor behavior

Defaults include:
- `termguicolors`
- line numbers + relative numbers
- `signcolumn=yes`
- `cursorline`
- `clipboard=unnamedplus`
- no swapfile
- 2-space indentation (`tabstop/shiftwidth/softtabstop`)
- `expandtab`, smart/auto indent
- `wrap=false`
- `scrolloff=6`
- sane completion defaults (`completeopt`)

---

## Keymaps

Leader is space, but your muscle-memory direct mappings are preserved as requested.

### Global shortcuts
- `w` → write
- `q` → quit
- `y` / `d` (normal + visual) → use system clipboard
- `yy` (insert mode) → leave insert mode
- `e` → open Oil file explorer
- `ff` → Telescope file picker
- `fb` → Telescope buffer picker
- `fg` → Telescope grep picker
- `h` → Telescope help picker
- `gw` → save and commit with AI message helper

### Project terminal workflow
- `rr` → run current project/file
- `rb` → build current project
- `rc` → close project terminal
- `rt` → focus project terminal

### LSP defaults
- `K` hover
- `gd` definition
- `gD` declaration
- `gi` implementation
- `gr` references
- `<leader>lr` rename
- `<leader>la` code action
- `<leader>lf` format
- `<leader>ld` diagnostics float
- `[d` / `]d` previous/next diagnostic

---

## Run/build workflow details

This config keeps your project terminal concept:

- Uses a **reusable bottom split terminal**
- Sends run/build commands into that split
- Returns focus to your previous editing window after sending

Detection rules:
- `Cargo.toml` → `cargo run` / `cargo build`
- `package.json` → `npm run dev` / `npm run build`
- `flake.nix` → `nix run` / `nix build`
- Python file → `python3 <current-file>` (run only)
- Lua file → `lua <current-file>` (run only)

Commands also exist:
- `:ProjectRun`
- `:ProjectBuild`

---

## Git commit AI flow (`gw`)

The workflow keeps your original concept:

1. Save current buffer.
2. Detect git repository root from current buffer location.
3. Run external helper script: `scripts/git-commit-ai.py`.
4. Open `vim.ui.input` with suggested commit message prefilled.
5. Run `git commit -a -m "<final message>"`.

If the script fails, returns empty output, or you are not in a git repo, a clear notification is shown.

---

## Install / update plugins

First launch after cloning:
- Open Neovim and let lazy bootstrap itself automatically.

Useful lazy commands:
- `:Lazy` open lazy UI
- `:Lazy sync` install/update/remove to match spec
- `:Lazy update` update plugins
- `:Lazy clean` remove unused plugins
- `:Lazy health` plugin health checks

---

## Notes

- LSP wiring uses Neovim 0.11 native APIs: `vim.lsp.config()` + `vim.lsp.enable()`.
- This setup intentionally avoids nightly-only APIs and heavy abstractions.
- Files are small on purpose so it is easy to maintain months later.
- Extend by adding plugin specs in `lua/plugins/` and wiring new behavior in
  `lua/core/` or `lua/features/`.
