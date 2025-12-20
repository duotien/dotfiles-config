# Neovim Configuration

This directory contains custom Neovim configuration files, including LSP server setups for Python development.

## Configuration Structure

### Core Configuration
The main configuration is loaded through `init.lua` which sets up:
- Plugin management with lazy.nvim
- Keybindings and mappings
- UI settings and preferences
- LSP integration

### LSP Server Configurations

#### Python Development Setup

This configuration uses a coordinated approach with two LSP servers for Python development:

##### Pyright Configuration (`nvim/after/lsp/pyright.lua`)
- Disables Pyright's import organization to allow Ruff to handle this task
- Disables Python analysis to let Ruff handle linting and analysis

##### Ruff Configuration (`nvim/after/lsp/ruff.lua`)
- Disables hover functionality from Ruff to avoid conflicts with Pyright
- This coordination ensures both tools work together without overlapping features

This approach provides the best of both worlds: Pyright's advanced code completion and type checking, combined with Ruff's fast linting and formatting capabilities.

## Plugin Management

Plugins are managed using lazy.nvim, with configurations in:
- `lua/duotien/plugins/` - Main plugin definitions
- `lua/duotien/plugins/lsp/` - LSP-specific plugin configurations

## Key Features

- Custom keybindings with leader key (space) and local leader (\)
- LSP integration with code completion, diagnostics, and navigation
- Multiple color schemes available
- Plugin configurations for LSP, treesitter, telescope, etc.
