# nvim-mcp

Neovim as an MCP server for AI agents (opencode). The flagship tool,
`propose_edit`, gives the agent an **in-buffer, review-gated edit flow**:
the AI proposes one or more hunks of a file → each renders as a highlighted
diff in *your* nvim buffer (new text real, old text as ghost lines) → you
accept or reject **per hunk** → the agent learns the outcome.

```
opencode daemon ──MCP stdio──> .venv/bin/python server.py      (this project)
                                  │
                                  │ pynvim (msgpack-RPC socket)
                                  ▼
                            your interactive nvim
                            ┌──────────────────────────────┐
                            │ lua/nvim_mcp/diff.lua        │
                            │ render(): per hunk — real    │
                            │          new lines (DiffAdd) │
                            │          + ghost old lines   │
                            │          (virt_lines) +      │
                            │          choice line         │
                            │ decide(): counts resolved    │
                            └──────────────────────────────┘
                                  │
        Python polls decide() every 200 ms (non-blocking RPC)
                                  │
   ALL hunks resolved → Python writes the BUFFER content to disk
   (user's mid-review edits included), clears the modified flag
```

**Why non-blocking:** a blocking RPC chunk (e.g. `vim.wait` inside one
`exec_lua` call) permanently wedges this nvim build's event loop — typeahead
and TUI die. So the Lua side is two small entry points, and the
human-in-the-loop (the polling loop) lives in Python. nvim's main loop stays
free between polls, so keypresses fire keymaps and the UI redraws normally.

## Install

1. **Python deps** (project venv — system Python is never touched):
   ```sh
   cd nvim/local/nvim-mcp && uv sync
   ```
2. **Interactive side:** nothing to do — `nvim/lua/plugins/nvim_mcp.lua`
   (a lazy local-plugin spec, `dir =`) puts `lua/` on the runtimepath.
   The plugin is passive: it does nothing until the MCP server connects.
3. **Agent side:** apply `opencode.jsonc.snippet` under `"mcp"."servers"` in
   `~/.config/opencode/opencode.jsonc`, then restart the daemon
   (`opencode serve --service`). The daemon spawns `server.py` per session
   and kills it on disconnect — no port, no service, nothing listening.
4. **Routing (optional but recommended):** an `edit-ask` agent with
   `edit: deny` + `nvim-mcp_propose_edit: allow` forces every file edit
   through review (opencode v2 withholds denied tools from the catalog, so
   there is no bypass).

## Usage

Ask the (routed) agent to edit a file. The call blocks until you decide in
nvim. The diff appears in the target buffer, headed by a **choice line**
above the old text:

```
>>> [a]ccept   [r]eject
qux = 200        ← old text (red)
quux = 300       ← new text (green)
```

Navigate freely — the buffer is **readonly** while the proposal is pending.
To decide, put the cursor on the `a` (or `r`) character of the choice line
and press `<CR>`:

| Action | Effect |
|---|---|
| cursor on `a` + `<CR>` | **accept** — the file is written to disk; the buffer's `+` flag is cleared (no `:w`) |
| cursor on `r` + `<CR>` | **reject** — buffer restored byte-identical; the agent receives the rejection and adapts |

Plain `a`/`r` keys are never mapped, so normal navigation can't decide by
accident; `<CR>` anywhere else is a no-op.

## Tools

| Tool | Purpose |
|---|---|
| `propose_edit(path, old_str, new_str)` | The review-gated edit. Validates `old_str` occurs exactly once on disk, renders the diff, returns the decision string. |
| `ping()` | Health check; proves the "one Python file per tool" extension pattern. |

Adding a tool = one file in `tools/` + one `mcp.tool()(fn)` line in
`server.py`. Expansion roadmap: `.epic-tasks/backlogs/task-nvim-mcp-expansion.md`.

## Failure modes (all fail safe — no write ever happens without a rendered,
reviewed proposal)

| Situation | What the agent receives |
|---|---|
| `old_str` missing / ambiguous on disk | `rejected: old_str not found…` / `occurs N times…` |
| Target buffer has **unsaved** changes that diverge from disk | `rejected: buffer has unsaved changes - save it (:w) and ask the agent again` (prevents the agent's disk-based write from clobbering your unsaved work) |
| No interactive nvim running / unreachable | `rejected: cannot reach nvim (…) — open nvim and retry` |
| nvim restarts **during** review | `rejected: nvim restarted during review - please re-run the edit` (the pending diff lived in the old instance's memory) |
| Two proposals overlap | second one: `rejected: another proposal is pending` (multi-file edits = sequential per-file rounds) |

## Development notes

- **Type check:** `pyright nvim_bridge.py tools/ server.py` (config in
  `pyproject.toml`; global pyright, venv at `.venv`).
- **Testing:** the real flow needs a human keypress — test against a scratch
  file in `.tmp/` (gitignored) with your interactive nvim open in the repo.
  `.tmp/e2e-test.md` is the E2E spec you can hand to the edit-ask agent.
- **Lua changes need a reload:** `require` caches modules — after editing
  `lua/nvim_mcp/diff.lua`, run
  `:lua package.loaded['nvim_mcp.diff'] = nil` (or restart nvim).
- **Never kill the `server.py` processes** — the daemon does not
  auto-respawn a dead MCP server. Reconnect via `/mcps` in the opencode TUI
  or a session restart.
- **Socket discovery:** this custom nvim build has no `nvim --server-list`;
  `nvim_bridge.discover_socket()` globs `$XDG_RUNTIME_DIR/nvim.<pid>.0`,
  probes each candidate for liveness (sockets linger after death), and
  prefers the instance with a controlling TTY.

## Limitations (task3+ candidates)

- One proposal at a time (per design); multi-file requests are sequential rounds.
- Target is the TTY-holding nvim; with several interactive instances the
  pick is first-by-mtime (no explicit chooser yet).
- Dirty buffers are rejected, not merged (save first).
- The diff renders in the current window of the target buffer (no floating
  window yet).
