# Keybindings

This document outlines all the custom keybindings used in this dotfiles configuration.

## Neovim Keybindings

### General
- `<Space>` - Leader key (`\` is the local leader)
- `<leader>ps` - Open Neovim configuration file
- `<leader>pv` - Open Netrw file explorer
- `<leader>z` - Zen mode (snacks; press again to exit)
- `<Space>` (pause) - which-key popup showing all mappings

### Finder (snacks picker)
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Find buffers
- `<leader>uc` - Colorscheme picker (live preview)

### Git (snacks picker)
- `<leader>gl` - Git log
- `<leader>gs` - Git status (`<Tab>` toggles staging)

### LSP (buffer-local, active when a language server attaches)
- `K` - Hover docs
- `<C-h>` in insert mode - Signature help
- `<leader>vca` - Code action
- `<leader>vrn` - Rename symbol
- `<leader>vf` - Format buffer
- `<leader>vd` - Diagnostics float on current line
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `<leader>pr` - Restart LSP client

### LSP built-ins (no config, Nvim native)
- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gO` - Document symbols
- `gr` - References (split) / `grr` - References (quickfix)
- `gy` - Go to type definition

## Zsh Keybindings

### General
- `ls` - Colored directory listing
- `la` - Colored directory listing with hidden files

## Tmux Keybindings

### Window Management
- `|` - Split window vertically
- `-` - Split window horizontally
- `r` - Reload configuration

### Mouse Support
- Mouse support is enabled for scrolling and clicking
