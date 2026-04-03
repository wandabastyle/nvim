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

### Language support

- Built-in Neovim LSP with:
  - `lua_ls` (Lua language server)
  - `nixd` (Nix language server)
- Nix formatting via `nixfmt` (configured through `nixd`)

---

## Manual install on Arch Linux (with `yay`)

Install Neovim and command-line tools used by this config:

```bash
yay -S --needed \
  neovim git ripgrep fd lua-language-server nixd nixfmt
```

### Notes

- `ripgrep` is used by `mini.pick.grep`.
- `fd` is commonly used by modern pickers/file tools and is recommended.
- `lua-language-server` and `nixd` are required for LSP support for Lua and Nix.
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
4. Open a Lua or Nix file and test:
   - completion while typing,
   - `<leader>lf` formatting,
   - picker mappings (`<leader>ff`, `<leader>fg`).
