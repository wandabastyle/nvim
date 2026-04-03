# Neovim Config

This repository contains a minimal Lua-based Neovim setup focused on:

- sensible editor defaults,
- built-in LSP + completion (no `nvim-cmp`),
- fast file/buffer/project picking,
- simple Git and file explorer integrations.

---

## What this config enables

### Editor defaults

- True color support (`termguicolors`)
- Absolute + relative line numbers
- No swapfile
- System clipboard integration (`unnamedplus`)
- Always-visible sign column
- Cursorline highlighting
- Rounded window borders
- 2-space indentation defaults (`tabstop`, `shiftwidth`, `softtabstop`)
- Smart/auto indent enabled
- Line wrapping disabled

### Theme + UI

- **tokyonight** (`tokyonight-moon` variant)
- **lualine** statusline
- **nvim-web-devicons** for file icons

### Navigation and files

- **mini.pick** for file, buffer, grep, and help pickers
- **oil.nvim** as a file explorer
- Hidden files are shown in Oil

### Git

- **gitsigns.nvim** for inline Git hunk signs/actions

### Project run/build terminal

- Built-in project-aware `:ProjectRun` and `:ProjectBuild` commands
- Reusable horizontal terminal split (height 12) for build/run output
- Rust projects (`Cargo.toml`) run with `cargo run` and build with `cargo build`
- Python files run with `python <current-file>`

### Language support

- Built-in Neovim LSP with:
  - `lua_ls` (Lua language server)
  - `nixd` (Nix language server)
  - `rust_analyzer` (Rust language server)
  - `pylsp` (Python language server)
- Nix formatting via `nixfmt` (configured through `nixd`)

---

## Neovim version requirement

This config currently targets **Neovim 0.13.x** APIs.

- As of now, Neovim **0.12.x** is the stable release line.
- Treat **0.13.x** as nightly/pre-release for now.
- If you run this config on 0.12, you may hit missing API errors (for example around newer built-in LSP/completion behavior).

### Install/update guidance for 0.13.x (nightly)

Use a package/build that explicitly tracks nightly (0.13.x), then verify:

```bash
nvim --version
```

You should see a `v0.13` version string in the first line.

If your package manager only ships 0.12 stable, install a nightly channel/package (often named `neovim-nightly`) or build Neovim from source and keep it updated.

---

## Manual install on Arch Linux (with `yay`)

Install Neovim nightly (0.13.x) and command-line tools used by this config:

```bash
yay -S --needed \
  neovim-nightly-bin git ripgrep fd \
  lua-language-server nixd nixfmt \
  rust-analyzer python-lsp-server python-lsp-black
```

### Notes

- Use a nightly package (`neovim-nightly-bin`) so you are on Neovim 0.13.x APIs.
- `ripgrep` is used by `mini.pick.grep`.
- `fd` is commonly used by modern pickers/file tools and is recommended.
- `lua-language-server`, `nixd`, `rust-analyzer`, and `python-lsp-server` are required for LSP support for Lua, Nix, Rust, and Python.
- `python-lsp-black` enables the configured Black formatter plugin inside `pylsp`.
- `nixfmt` is used by the Nix LSP formatting configuration.
- For file icons to render correctly, use a **Nerd Font** in your terminal.

---

## Plugin list

Plugins are installed via `vim.pack.add`:

- `folke/tokyonight.nvim`
- `nvim-tree/nvim-web-devicons`
- `nvim-lualine/lualine.nvim`
- `neovim/nvim-lspconfig`
- `echasnovski/mini.pick`
- `echasnovski/mini.pairs`
- `stevearc/oil.nvim`
- `lewis6991/gitsigns.nvim`

---

## Keyboard shortcuts

Leader key is set to **Space**.

### General

- `<leader>w` → Save current file
- `<leader>q` → Quit window
- `<leader>y` (normal/visual/select) → Yank to system clipboard
- `<leader>d` (normal/visual/select) → Delete to system clipboard
- `<leader>rr` → Run current project/file (`:ProjectRun`)
- `<leader>rb` → Build current project (`:ProjectBuild`)

### Line movement

- `<C-Down>` (normal) → Move current line down
- `<C-Up>` (normal) → Move current line up

### Insert mode convenience

- `yy` (insert) → Exit insert mode (acts like `<Esc>`)

### Picker / search (`mini.pick`)

- `<leader>ff` → Find files
- `<leader>fb` → List/open buffers
- `<leader>fg` → Grep in project
- `<leader>h` → Search help tags

### File explorer (`oil.nvim`)

- `<leader>e` → Open Oil file explorer

### Build / run terminal

- `:ProjectRun` → Run current project/file in reusable horizontal terminal split
- `:ProjectBuild` → Build current project in reusable horizontal terminal split
- In the project terminal:
  - `q` (normal mode) → Close split
  - `<C-q>` (terminal mode) → Close split

### LSP

- `<leader>lf` → Format current buffer via LSP

### Completion menu navigation (insert mode)

- `<Tab>` → Next completion item (if menu visible), otherwise insert tab
- `<S-Tab>` → Previous completion item (if menu visible)
- `<CR>` → Confirm selected completion item (if menu visible), otherwise newline

---

## How autocompletion works in this config

This setup uses **Neovim's built-in LSP completion API** directly, not a third-party completion framework like `nvim-cmp`.

### 1) Completion capabilities come from attached LSP servers

When an LSP server attaches, an `LspAttach` autocmd runs. If the server supports
`textDocument/completion`, completion is enabled for that buffer with:

- `vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })`

`autotrigger = true` means completion suggestions can appear automatically as you type.
This config also broadens LSP `triggerCharacters` to printable ASCII so normal identifier
typing (letters/numbers/symbols) can auto-trigger completion more consistently.

This can be a little slower on some servers, so `<C-Space>` remains a manual fallback.

You can always force a completion request with:

- `<C-Space>` in insert mode

### 2) Completion popup behavior (`completeopt`)

`completeopt` is configured as:

- `menu,menuone,noinsert,noselect`

This means:

- Show popup menu even for one match
- Do not auto-insert a suggestion
- Do not preselect an item automatically

So suggestions appear, but you explicitly choose what to accept.

### 3) Key behavior while the popup menu is visible

Insert mode mappings are conditional with `pumvisible()`:

- If popup visible:
  - `<Tab>` sends `<C-n>` (next item)
  - `<S-Tab>` sends `<C-p>` (previous item)
  - `<CR>` sends `<C-y>` (accept completion)
- If popup not visible:
  - `<Tab>`, `<S-Tab>`, `<CR>` behave normally

This gives a lightweight completion flow with no extra completion plugin.

---

## Quick start

1. Install dependencies with `yay` (see above).
2. Launch Neovim:

   ```bash
   nvim
   ```
3. Let plugins sync/install the first time.
4. Open a Lua, Nix, Rust, or Python file and test:
   - completion while typing,
   - manual completion with `<C-Space>` (fallback if auto-trigger feels slow or misses in edge cases),
   - `<leader>lf` formatting,
   - picker mappings (`<leader>ff`, `<leader>fg`),
   - project run/build (`<leader>rr`, `<leader>rb`).
