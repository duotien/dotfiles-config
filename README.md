# Dot-files configs

clone this repo recursively:

```sh
git clone --recurse-submodules https://github.com/duotien/dotfiles-config.git
cd dotfiles-config
```

## zsh

```sh
ln -s $(pwd)/zsh/.zshenv ~/.zshenv
ln -s $(pwd)/zsh ~/.config/zsh
```

## neovim-config
My custom neovim config

require neovim >= 0.11

using lazy
