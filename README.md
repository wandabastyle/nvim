# Minimal Neovim Config (Linux / Arch)

A personal, modular Neovim configuration written in Lua for Linux (primarily Arch Linux).

This setup is for users who want a practical editor with LSP, formatting, linting, and a clean git workflow without heavy Neovim distributions or frameworks.

## Features

- Built-in LSP setup for common languages with completion powered by `blink.cmp`.
- Lazy-loaded plugins managed by `lazy.nvim`, with Mason-assisted LSP/tool installation.
- Formatting and linting workflow integrated into editor actions.
- Git-oriented workflow, including quick run/build commands and commit support.
- AI commit message generation from git diff using Ollama.
- Modular structure (`init.lua` bootstrap + `lua/config/*` organization).

## Requirements

Required base tools:

- `neovim-nightly-bin`
- `git`
- `ripgrep`
- `fd`
- `nodejs` (required by many language servers)
- `python` (for scripts)
- `stylua` (Lua formatter; Mason can install it)
- `shellcheck` (Mason can install it)
- `shfmt` (shell formatting; Mason can install it)
- `clang` or `clangd`

LSP servers/tools used by this config:

- `lua-language-server` (`lua_ls`)
- `rust-analyzer`
- `ty` (`ty`)
- `ruff` (`ruff`)
- `typescript` + `typescript-language-server` (`ts_ls`)
- `svelte-language-server` (`svelte`)

Optional but recommended:

- `lazygit`
- `ollama`

Arch Linux / `yay` example (base tools + LSP tools):

```bash
yay -S neovim-nightly-bin git ripgrep fd nodejs python stylua shellcheck shfmt clang lua-language-server rust-analyzer ty ruff typescript typescript-language-server svelte-language-server lazygit ollama
```

`neovim-nightly-bin` is used to avoid occasional `tree-sitter` ABI mismatches that can happen with source-built `neovim-git` after system library upgrades.

## Installation

Back up your existing Neovim config first if you already have one:

```bash
mv ~/.config/nvim ~/.config/nvim.bak
```

Clone this repository to `~/.config/nvim`:

```bash
git clone <your-repo-url> ~/.config/nvim
```

Start Neovim:

```bash
nvim
```

## Keybindings

This is a concise overview of keymaps defined in the config.

### General

| Key | Action |
| --- | --- |
| `<leader>w` | Save file |
| `<leader>q` | Quit window |
| `<leader>y` | Yank to system clipboard |
| `<leader>d` | Delete to system clipboard |
| `<leader>lk` | Show buffer keymaps (`which-key`) |
| `<leader>ff` | Find files (`snacks.nvim`) |
| `<leader>fb` | Find buffers (`snacks.nvim`) |
| `<leader>fg` | Live grep (`snacks.nvim`) |
| `<leader>fh` | Help tags picker |
| `<leader>fr` | Recent files |
| `<leader>fd` | Diagnostics picker |
| `<leader>fc` | Find config files |
| `<leader>e` | Open file explorer (`Oil`) |
| `<C-Up>` / `<C-Down>` | Move current line up/down |
| `<Esc>` | Clear search highlight |

### LSP

| Key | Action |
| --- | --- |
| `K` | Hover documentation |
| `gd` | Go to definition |
| `gr` | Find references |
| `<leader>lf` | Format buffer |
| `<leader>lr` | Rename symbol |
| `<leader>la` | Code action |
| `<leader>ld` | Line diagnostics (floating window) |
| `<leader>ll` | Diagnostics list (location list) |
| `<leader>ls` | Workspace symbol search (prompt) |
| `<leader>lp` / `<leader>ln` | Previous / next diagnostic |
| `<C-Space>` (insert) | Trigger completion |

Completion is powered by `blink.cmp`, and LSP capabilities are merged via `require("blink.cmp").get_lsp_capabilities(...)`.
Snippet expansion uses Neovim's native `vim.snippet` engine (no external snippet engine/plugin required).

Mason provides installation helpers for Lua, Rust, Python, TypeScript, Svelte, and common formatter/linter tools. Open it with `<leader>mm`.

### Tools

| Key | Action |
| --- | --- |
| `<leader>mm` | Open Mason registry |
| `<leader>xx` | Workspace diagnostics (`trouble.nvim`) |
| `<leader>xb` | Buffer diagnostics (`trouble.nvim`) |
| `<leader>xs` | Symbols (`trouble.nvim`) |
| `<leader>xl` | Location list (`trouble.nvim`) |
| `<leader>xq` | Quickfix list (`trouble.nvim`) |
| `<leader>tt` | TODO list |
| `<leader>tq` | TODO quickfix |
| `<leader>tp` / `<leader>tn` | Previous / next TODO comment |

### Git

| Key | Action |
| --- | --- |
| `<leader>gm` | Save and commit the current file (AI-assisted message prompt) |

### AI / Commit

| Key | Action |
| --- | --- |
| `<leader>gm` | Generate a commit message, edit it, then commit only the current file path |

## AI Commit Messages (Ollama)

The commit helper uses a local Python script to generate commit message suggestions from the current git diff, then the Lua workflow commits only the current buffer's file path.

- Ollama must be installed and running.
- The config includes user-systemd integration to start/stop `ollama.service` and manage a delayed stop timer.
- Trigger with `<leader>gm`, review/edit the suggested message, then confirm the current-file commit.

## Notes / Philosophy

- Minimal and maintainable by design.
- No heavy frameworks or starter distros (for example, no LazyVim or AstroNvim).
- Assumes the user is comfortable with Neovim basics and editing Lua config files.
