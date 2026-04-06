# Minimal Neovim Config (Linux / Arch)

A personal, modular Neovim configuration written in Lua for Linux (primarily Arch Linux).

This setup is for users who want a practical editor with LSP, formatting, linting, and a clean git workflow without heavy Neovim distributions or frameworks.

## Features

- Built-in LSP setup for common languages with completion powered by `blink.cmp`.
- Formatting and linting workflow integrated into editor actions.
- Git-oriented workflow, including quick run/build commands and commit support.
- AI commit message generation from git diff using Ollama.
- Modular structure (`init.lua` bootstrap + `lua/config/*` organization).

## Requirements

Required base tools:

- `neovim-git`
- `git`
- `ripgrep`
- `fd`
- `nodejs` (required by many language servers)
- `python` (for scripts)
- `stylua` (Lua formatter)
- `shellcheck`
- `shfmt` (shell formatting)
- `clang` or `clangd`

LSP servers/tools used by this config:

- `lua-language-server` (`lua_ls`)
- `nixd` (`nixd`)
- `rust-analyzer`
- `python-lsp-server` (`pylsp`)
- `typescript` + `typescript-language-server` (`ts_ls`)

Optional but recommended:

- `lazygit`
- `ollama`

Arch Linux / `yay` example (base tools + LSP tools):

```bash
yay -S neovim-git git ripgrep fd nodejs python stylua shellcheck shfmt clang lua-language-server nixd rust-analyzer python-lsp-server typescript typescript-language-server lazygit ollama
```

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
| `<leader>ff` | Find files (`mini.pick`) |
| `<leader>fb` | Find buffers (`mini.pick`) |
| `<leader>fg` | Live grep (`mini.pick`) |
| `<leader>h` | Help tags picker |
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
| `[d` / `]d` | Previous / next diagnostic |
| `<C-Space>` (insert) | Trigger completion |

Completion is powered by `blink.cmp`, and LSP capabilities are merged via `require("blink.cmp").get_lsp_capabilities(...)`.
Snippet expansion uses Neovim's native `vim.snippet` engine (no external snippet engine/plugin required).

### Git

| Key | Action |
| --- | --- |
| `<leader>gw` | Save current file and create git commit (AI-assisted message prompt) |

### AI / Commit

| Key | Action |
| --- | --- |
| `<leader>gw` | Generate commit message from diff, edit it, then run `git commit -a -m` |

## AI Commit Messages (Ollama)

The commit helper uses a local Python script to generate commit message suggestions from the current git diff.

- Ollama must be installed and running.
- The config includes user-systemd integration to start/stop `ollama.service` and manage a delayed stop timer.
- Trigger with `<leader>gw`, review/edit the suggested message, then confirm commit.

## Notes / Philosophy

- Minimal and maintainable by design.
- No heavy frameworks or starter distros (for example, no LazyVim or AstroNvim).
- Assumes the user is comfortable with Neovim basics and editing Lua config files.
