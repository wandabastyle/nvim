# Neovim Config

> [!WARNING]
> This config targets **Neovim 0.13.x** APIs (nightly/pre-release at the time of writing).
> Older versions (including 0.12.x stable) can fail with missing API errors.

This repository contains a minimal Lua Neovim setup with modular config files, built-in LSP/completion, and a reusable in-editor run/build terminal workflow.

## Structure

- `init.lua` — bootstrap + module loading only
- `lua/config/options.lua` — editor options / `completeopt`
- `lua/config/keymaps.lua` — global mappings
- `lua/config/commands.lua` — user commands (`:ProjectRun`, `:ProjectBuild`)
- `lua/config/autocmds.lua` — global autocmd placeholder
- `lua/features/project_terminal.lua` — reusable Neovim terminal split workflow
- `lua/plugins/init.lua` — plugin install list via `vim.pack.add`
- `lua/plugins/ui.lua` — colorscheme/UI/picker/oil/gitsigns setup
- `lua/plugins/editing.lua` — autopairs + optional `nvim-cmp` integration hook
- `lua/plugins/lsp.lua` — LSP server setup, completion mappings, `LspAttach`

## Plugins

Installed with `vim.pack.add`:

- `folke/tokyonight.nvim`
- `nvim-tree/nvim-web-devicons`
- `nvim-lualine/lualine.nvim`
- `neovim/nvim-lspconfig`
- `echasnovski/mini.pick`
- `stevearc/oil.nvim`
- `lewis6991/gitsigns.nvim`
- `windwp/nvim-autopairs`

## Project run/build terminal

- Commands:
  - `:ProjectRun`
  - `:ProjectBuild`
- Opens a **bottom horizontal split** terminal (height 12) using Neovim's built-in terminal.
- Reuses the same terminal buffer/window when possible.
- `:ProjectRun` / `:ProjectBuild` sends commands to the project terminal and then restores focus to the previously active editing window.
- Terminal close mappings:
  - `q` in normal mode
  - `<C-q>` in terminal mode
- Project behavior:
  - Rust (`Cargo.toml` found):
    - Run: `cargo run`
    - Build: `cargo build`
  - Python:
    - Run: `python <current-file>`
    - Build: warns that there is no default Python build target
  - Unknown project: warning notification

Default mappings:

- `<leader>rr` → `:ProjectRun`
- `<leader>rb` → `:ProjectBuild`
- `<leader>rc` → close project terminal window
- `<leader>rt` → focus project terminal window (enters terminal insert mode)

## Consistent Enter behavior in braces

`nvim-autopairs` handles newline splitting between pairs like `{|}` when pressing `<CR>`.

This config routes insert-mode `<CR>` through a single mapping:

- popup menu visible (`pumvisible() == 1`) → confirm completion (`<C-y>`)
- popup menu hidden → run `require("nvim-autopairs").autopairs_cr()`

This keeps brace newline behavior consistent across languages (Rust, C/C++, JavaScript, etc.) while preserving completion confirmation behavior.

`nvim-autopairs` is configured with:

- `check_ts = true` for Treesitter-aware pairing behavior
- `enable_check_bracket_line = false` so `<CR>` can still split `{|}` in common inline cases

If `hrsh7th/nvim-cmp` is installed later, `lua/plugins/editing.lua` auto-hooks
`cmp.event:on("confirm_done", ...)` to keep completion-confirm pair insertion working.

## LSP and completion

Built-in Neovim LSP (no `nvim-cmp`) with:

- `lua_ls`
- `nixd`
- `rust_analyzer`
- `pylsp`

Behavior kept from previous config:

- `LspAttach` buffer-local mappings (`K`, `gd`, `gr`, diagnostics, rename/code actions)
- manual completion trigger: `<C-Space>`
- aggressive auto-trigger completion by widening trigger characters to printable ASCII
- popup control mappings in insert mode:
  - `<Tab>` / `<S-Tab>` navigate popup when visible
  - `<CR>` confirms popup selection when visible

## After pulling updates

Inside Neovim, run:

```vim
:packupdate
```

(or your usual `vim.pack` update flow) to fetch `nvim-autopairs` and remove old plugin state.
