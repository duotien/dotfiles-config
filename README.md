# Dot-files configs

clone this repo recursively:

```sh
git clone --recurse-submodules https://github.com/duotien/dotfiles-config.git
cd dotfiles-config
```

## zsh

Customization for `zsh`. Create a symbolic link of .zshenv to your `$HOME` directory.

```sh
ln -s $(pwd)/zsh/.zshenv ~/.zshenv
ln -s $(pwd)/zsh ~/.config/zsh
```

## neovim-config

My custom neovim config

require neovim >= 0.11

using lazy

## tmux

```
ln -s $(pwd)/tmux ~/.config/tmux
```
