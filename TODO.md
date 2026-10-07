# TODO

## Neovim

- [x] `<leader>fh` — find help keymap (snacks picker help tags) — done 2026-10-05
- [x] Ruff for Python formatting (Mason `ensure_installed`) — done 2026-10-05
- [x] `nvim-lsp-file-operations` — LSP-aware file rename/create/delete — done 2026-10-05
- [x] which-key: label the `<leader>o` group — done 2026-10-05
- [x] Minuet AI ghost text (Ollama 1.5b) — done 2026-10-05 (`4142658`)
- [x] CodeCompanion (local 27b @ :30000) — added 2026-10-06, **removed** 2026-10-07 (`547eeed`); NInfer `strict` tools 400
- [x] Make opencode & minuet optional (`vim.g.opts` switchboard) — done 2026-10-07 (`c0b73bb`)
- [x] epic-tasks skill installed + `.epic-tasks/` scaffolded (tmux convention) — done 2026-10-07 (`474a366`)

## Next up

See `PLANS.md` for integration notes.

- [ ] `avante.nvim` v0.2.3 — inline edit + agentic mode via NInfer (plan in PLANS.md §3)
- [ ] opencode.nvim extras: operator prompts, `@gitdiff`/`@gitstatus` contexts, `commit` select prompt (optional: statusline)
- [ ] opencode.nvim: report SSE heartbeat/watchdog flake upstream; `:Lazy update` when fixed

## On hold (discussed, not started)

- Stylua for Lua formatting + bulk-format `nvim/`
- Regenerate stale `nvim/PLUGINS.md`
- `uvinit` zsh function (append `[tool.pyright]` block to new projects)
- snacks extras: explorer, terminal, words, statuscolumn
- Delete merged branch `fix/pyright-ruff`
- Merge (or close) `refactor/nvim` when happy with the rebuild
