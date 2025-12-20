# Dotfiles Configuration

Personal configuration files for Neovim, Zsh, and Tmux development environment.

## Overview

This repository contains my personal dotfiles configuration for a customized development environment. It includes configurations for Neovim (with lazy.nvim plugin manager), Zsh shell, and Tmux terminal multiplexer. These configurations are designed to improve productivity and provide a consistent development experience across different machines.

## Features

### Neovim Configuration
- Uses lazy.nvim for plugin management
- Custom keybindings with leader key (space) and local leader (\)
- LSP (Language Server Protocol) integration with code completion, diagnostics, and navigation
- Custom UI settings (line numbers, colors, etc.)
- Multiple color schemes available (monokai, novel, etc.)
- Plugin configurations for LSP, treesitter, telescope, etc.

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

Neovim configuration will be automatically loaded when you start Neovim.

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
- Custom color scheme "novel"

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
- Use `<Space>` as leader key for custom mappings
- `<C-h>` in insert mode for signature help
- `K` to show documentation
- `<leader>pv` to open Netrw file explorer
- `<leader>ps` to open Neovim configuration file

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
3. For Neovim, plugins can be managed in `nvim/lua/duotien/plugins/`

## Contributing

This is a personal configuration repository. Feel free to fork and customize for your own needs, but no formal contribution process is established.

## License

This project is open source and available under the MIT License.
