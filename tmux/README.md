# Tmux Configuration

This directory contains custom Tmux terminal multiplexer configuration.

## Configuration Structure

### Main Configuration File

- `tmux.conf` - Main Tmux configuration file

## Key Features

- Mouse support enabled for scrolling and clicking
- Custom color scheme
- Split window bindings:
  - `|` to split window vertically
  - `-` to split window horizontally
  - `r` to reload configuration
- History and terminal settings

## Setup Instructions

To set up this Tmux configuration:

```sh
ln -s $(pwd)/tmux ~/.config/tmux
```

## Customizations

### Window Management
- `|` - Split window vertically
- `-` - Split window horizontally
- `r` - Reload configuration

### Mouse Support
- Mouse support is enabled for scrolling and clicking

### Color Scheme
- Custom color scheme applied

## Usage Tips

- Use `|` to split window vertically
- Use `-` to split window horizontally
- Use `r` to reload configuration
