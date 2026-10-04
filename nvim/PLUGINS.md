# Installed Plugins

All plugins are managed by **lazy.nvim** and installed in `~/.local/share/nvim/lazy/`.
Versions are pinned in `lazy-lock.json`.

| Plugin | Purpose | Config | Load |
|---|---|---|---|
| `lazy.nvim` | Plugin manager | `lua/duotien/lazy.lua` | boot |
| `plenary.nvim` | Shared Lua utilities (dep for many plugins) | `lua/duotien/plugins/init.lua` | boot |
| `snacks.nvim` | Picker, terminal, notifier, zen mode, toggles, word jumps, statuscolumn | `lua/duotien/plugins/snacks.lua` | boot (priority 1000) |
| `nvim-cmp` | Autocompletion engine (LSP + buffer + path sources) | `lua/duotien/plugins/nvim-cmp.lua` | InsertEnter |
| `cmp-buffer` | cmp source: text in current buffer | (dep of nvim-cmp) | with nvim-cmp |
| `cmp-path` | cmp source: file system paths | (dep of nvim-cmp) | with nvim-cmp |
| `lspkind.nvim` | VS Code-style icons in completion menu | (dep of nvim-cmp) | with nvim-cmp |
| `cmp-nvim-lsp` | cmp source: LSP completions; wires capabilities | `lua/duotien/plugins/lsp/lsp.lua` | BufReadPre / BufNewFile |
| `nvim-lspconfig` | LSP server definitions (pyright, ruff, clangd, lua_ls, jsonls) | `lua/duotien/plugins/lsp/lsp.lua` + `after/lsp/*.lua` | with cmp-nvim-lsp |
| `mason.nvim` | LSP server installer/manager | `lua/duotien/plugins/lsp/mason.nvim.lua` | with mason-lspconfig |
| `mason-lspconfig.nvim` | Auto-starts servers found via Mason; `ensure_installed`: lua_ls, pyright, clangd | `lua/duotien/plugins/lsp/mason.nvim.lua` | with cmp-nvim-lsp |
| `nvim-lsp-file-operations` | LSP file operations (rename/create/delete via LSP) | (dep, `config = true`) | with cmp-nvim-lsp |
| `lazydev.nvim` | LSP for this config's own Lua code | (dep, `opts = {}`) | with cmp-nvim-lsp |
| `nvim-treesitter` | Syntax highlighting, indent, incremental selection (lua, python, cpp, json, bash, markdown) | `lua/duotien/plugins/treesitter.lua` | BufReadPost / BufNewFile, build `:TSUpdate` |
| `telescope.nvim` | Fuzzy finder (files, grep, buffers, help tags) + LSP pickers (tag `0.1.8`) | `lua/duotien/plugins/telescope.lua` | with plenary |
| `which-key.nvim` | Keybinding hint popups (`<leader>?` buffer-local) | `lua/duotien/plugins/which-key.lua` | VeryLazy |
| `mini.pairs` | Smart bracket auto-pairing | `lua/duotien/plugins/mini.pairs.lua` | VeryLazy |
| `opencode.nvim` | OpenCode AI integration in side terminal (`<leader>oa/op/os/ot`) | `lua/duotien/plugins/opencode.lua` | with snacks |

## Notes

- **Mason-installed LSP servers** (in `~/.local/share/nvim/mason/bin/`): `clangd`, `lua-language-server`, `pyright`, `pyright-langserver`, `ruff`
- **Ruff** is also available via `uv tool install ruff` (newer version); Mason's copy takes precedence inside Neovim
- `image.nvim` and `molten-nvim` were previously in `lazy-lock.json` but are no longer installed (removed from the spec)
