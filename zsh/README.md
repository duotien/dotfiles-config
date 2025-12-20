# Zsh Configuration

This directory contains custom Zsh shell configuration files.

## Configuration Structure

### Main Configuration Files

- `.zshenv` - Environment variables and settings sourced during shell initialization
- `.zshrc` - Main shell configuration file for interactive shells
- `alias.sh` - Custom shell aliases

### Key Features

- Syntax highlighting with zsh-syntax-highlighting plugin
- Custom aliases (`ls`, `la`) for colored directory listings
- Custom prompt showing username and current directory
- Right-side timestamp display
- Integration with uv for shell completion

## Why .zshenv is in Home Directory

The `.zshenv` file must be placed in the home directory because it's sourced by zsh during initialization, before other configuration files. This file typically contains environment variables and settings that are needed early in the shell startup process.

## Setup Instructions

To set up this Zsh configuration:

```sh
# Create symbolic links
ln -s $(pwd)/zsh/.zshenv ~/.zshenv
ln -s $(pwd)/zsh ~/.config/zsh
```

## Customizations

### Aliases
- `ls` - Colored directory listing
- `la` - Colored directory listing with hidden files

### Prompt
- Shows username and current directory
- Right-side timestamp display

### Integration
- Integration with uv shell completion
