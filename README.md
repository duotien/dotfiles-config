# Dotfiles Configuration

Personal configuration files for Neovim, Zsh, and Tmux development environment.

## Overview

This repository contains my personal dotfiles configuration for a customized development environment. It includes configurations for Neovim (with lazy.nvim plugin manager), Zsh shell, and Tmux terminal multiplexer. These configurations are designed to improve productivity and provide a consistent development experience across different machines.

## Features

### Neovim Configuration
- lazy.nvim v11 for plugin management (`lazy-lock.json` pins all plugins)
- Modular layout: `init.lua` (entry point) + `lua/core/` (options, keymaps, autocmds, LSP keymaps) + `lua/plugins/` (per-domain plugin specs)
- LSP via Mason v2: pyright (Python) and lua_ls (Lua), with nvim-cmp completion
- snacks.nvim: dashboard, fuzzy picker (files/grep/buffers/git), notifier, zen mode, smooth scroll, quickfile, bigfile
- which-key.nvim keybinding popups, tokyonight colorscheme
- OpenCode v2 integration (`<leader>oa`/`<leader>ox`)
- nvim-mcp: local MCP server (Python, official `mcp` SDK v2, `uv` venv) exposing Neovim
  to opencode — in-buffer, review-gated AI edits (local plugin in `nvim/local/`;
  optional — register via the included `opencode.jsonc.snippet`)
- mini.pairs auto-pairing, lazydev for `vim.*` completion in this config
- Custom keybindings with leader key (space) and local leader (\)

### Zsh Configuration
- Syntax highlighting with zsh-syntax-highlighting plugin
- Custom aliases (ls, la)
- Custom prompt and timestamp display
- Integration with uv for shell completion

### Tmux Configuration
- Mouse support enabled
- Custom color scheme
- Split window bindings (vertical and horizontal)
- History and terminal settings

## Requirements

- Neovim >= 0.11
- Zsh shell
- Tmux
- git (plugin manager bootstrap, LSP servers via Mason)
- uv (Python environments for LSP; per-project `[tool.pyright] venv` config)
- OpenCode v2 (optional, for `<leader>oa`/`<leader>ox`)
- Nerd Font (recommended — plugin icons; JetBrainsMono Nerd Font used here)

## Installation

Clone this repository recursively:

```sh
git clone --recurse-submodules https://github.com/duotien/dotfiles-config.git
cd dotfiles-config
```

### Zsh Setup
Create symbolic links for Zsh configuration:

```sh
ln -s $(pwd)/zsh/.zshenv ~/.zshenv
ln -s $(pwd)/zsh ~/.config/zsh
```

The `.zshenv` file must be in the home directory because it's sourced by zsh during initialization, before other configuration files. This file typically contains environment variables and settings that are needed early in the shell startup process.
### Neovim Setup
Create symbolic link for Neovim configuration:

```sh
ln -s $(pwd)/nvim ~/.config/nvim
```

Start Neovim once; the lazy.nvim bootstrap in `init.lua` clones the plugin manager, and `:Lazy sync` installs the pinned plugins and Mason LSP servers.

### Tmux Setup
Create symbolic link for Tmux configuration:

```sh
ln -s $(pwd)/tmux ~/.config/tmux
```

## Configuration Details

### Neovim
- Leader key is set to space (`<Space>`)
- Local leader is set to backslash (`\`)
- Line numbers and relative line numbers enabled
- Tab settings: 4 spaces for indentation
- True color support enabled
- Colorscheme: tokyonight (storm style)
- Plugin specs live in `nvim/lua/plugins/` (one file per domain: treesitter, lsp, completion, snacks, whichkey, colorscheme, minipairs, opencode, neovim)
- Core behavior lives in `nvim/lua/core/` (options, keymaps, autocmds, lsp)

### Zsh
- Syntax highlighting enabled
- Aliases for `ls` and `la` commands
- Custom prompt showing username and current directory
- Right-side timestamp display
- Integration with uv shell completion

### Tmux
- Mouse support enabled
- Custom color scheme
- Split window bindings:
  - `|` to split window vertically
  - `-` to split window horizontally
  - `r` to reload configuration

## Usage Tips

### Neovim
- Use `<Space>` as leader key; pause to see the which-key popup
- `<leader>ff` / `<leader>fg` / `<leader>fb` — find files / live grep / buffers
- `<leader>gl` / `<leader>gs` — git log / git status
- `<leader>z` — zen mode
- `K` for hover docs; `[d` / `]d` for diagnostics in LSP buffers
- `<leader>oa` / `<leader>ox` — ask / select in OpenCode (v2 daemon required)

### Zsh
- Use custom aliases `ls` and `la` for colored directory listings
- Syntax highlighting for commands and output

### Tmux
- Use `|` to split window vertically
- Use `-` to split window horizontally
- Use `r` to reload configuration

## Keybindings

For detailed keybindings, please see [KEYBINDINGS.md](KEYBINDINGS.md).

## Customization

To customize any component:
1. Modify the relevant configuration files in the respective directories
2. Restart the application to see changes
3. For Neovim, plugin specs live in `nvim/lua/plugins/` (aggregated by `nvim/lua/plugins.lua`) and core behavior in `nvim/lua/core/`

## Contributing

This is a personal configuration repository. Feel free to fork and customize for your own needs, but no formal contribution process is established.

## License

This project is open source and available under the MIT License.
