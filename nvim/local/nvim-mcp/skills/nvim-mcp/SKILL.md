---
name: nvim-mcp
description: Target the Neovim buffer the user is looking at when working via opencode.nvim — current buffer, selection, and in-buffer edit review via the nvim-mcp MCP tools. Use when the user refers to "this file", "here", a selection, or asks to edit what they are looking at.
---

# nvim-mcp buffer targeting

Applies when the session is driven from Neovim via opencode.nvim — the
prompt starts with a `[nvim-mcp] buffer: <path> (line N)` line (the
**focused** buffer, updated per prompt). Trust it over cwd inference for
"this file" / "here".

- The user says "this file" / "here" / "the buffer I'm on" → call
  `nvim-mcp_current_buffer` to get the exact path + position before editing.
- The user refers to a selection ("this", "these lines", "the selected text")
  → call `nvim-mcp_get_selection`. If `active` is false, fall back to
  `nvim-mcp_current_buffer`.
- **Prefer `nvim-mcp_propose_edit`** over the native edit tool for files the
  user has open in Neovim: it routes each hunk through in-buffer review, so
  the user sees and accepts/rejects the change. The native edit tool bypasses
  that review.
- If `current_buffer` reports `modified: true`, tell the user to save first
  (unsaved buffer contents diverge from disk).
- `path` is `""` for buffers without a file (scratch/terminal/help) — those
  cannot be targeted by `propose_edit`.
