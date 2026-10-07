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
nvim. A proposal can carry **several hunks at once** — each is rendered
in the target buffer as a **choice line** above the new text, with the old
text ghosted as virtual lines:

```
>>> [a]ccept   [r]eject
quux = 300       ← new text (green, real line)
   qux = 200     ← old text (ghost, not a real line)
```

The buffer stays **editable** while the proposal is pending — anything you
type is folded into the disk write on resolution.

### Showing the target buffer

The render never steals your view:

- target buffer open in a window of the **current tab** → hop to it
- open in **another tab** → switch tab + hop
- **not open** → open in a **split** in the current window

If the current window is a float, the split is taken from a normal window
instead (the float keeps its place). The split is **not** auto-closed after
the decision — you close it when done.

Per-hunk decisions:

| Action | Effect |
|---|---|
| cursor on a hunk's `a` + `<CR>` | **accept** that hunk |
| cursor on a hunk's `r` + `<CR>` | **reject** that hunk (its new lines revert to the old) |
| `ct` / `co` anywhere on a hunk (choice line or new lines) | accept / reject **that** hunk, no cursor move needed |
| `]x` / `[x` | walk to next / previous **unresolved** hunk (centered; wraps; skips decided ones) |

After every decision the cursor auto-jumps to the next unresolved hunk, so
a review is: `]x`-walk, `ct`/`co` or `a`/`r`+`<CR>`, repeat. When the last
hunk is resolved, Python writes the **buffer content** to disk (your
mid-review edits included), skips the write when nothing changed, and
clears the buffer's `+` flag (no `:w`). Undo: the render is ONE undo step
and each decision is its own — `u` steps back one decision at a time
(you can also undo an individual decision), repeated `u`s walk back to the
pre-proposal buffer. (Documented limitation: this nvim build's `:undojoin`
can't chain decisions into the render's undo unit.)

Saving with `:w` mid-review **ends the session**: the buffer you saved IS
the file (unresolved hunks are kept as shown, their choice lines stripped),
and no further write happens.

Plain `a`/`r` keys are never mapped, so normal navigation can't decide by
accident; `<CR>` off a choice-line letter is a no-op.

## Tools

| Tool | Purpose |
|---|---|
| `propose_edit(path, edits=[{old_text, new_text}, …])` | The review-gated edit. Validates each `old_text` occurs exactly once (sequentially, in order), renders all hunks, returns the decision string. Legacy `old_str`/`new_str` wraps to one hunk. |
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
| `u` (undo) pressed **during** review | `aborted: review disturbed (undo?) - nothing written` — the guard detects the disturbed render and no disk write happens; re-run the edit to re-propose |
| `:w` **during** review | `resolved: user-saved, N unresolved hunk(s) kept as shown - buffer is the file` — the session ends; remaining choice lines are stripped by content (robust to your mid-review edits); no double write |
| hunk with `old_text == new_text` | `Rejected: hunk N: old_text and new_text are identical (no-op edit)` |

## Development notes

- **Type check:** `pyright nvim_bridge.py tools/ server.py` (config in
  `pyproject.toml`; global pyright, venv at `.venv`).
- **Testing:** the real flow needs a human keypress — test against a scratch
  file in `.tmp/` (gitignored) with your interactive nvim open in the repo.
  `.tmp/e2e-test.md` is the E2E spec you can hand to the edit-ask agent.
- **Lua changes need a reload:** `require` caches modules — after editing
  `lua/nvim_mcp/diff.lua`, run
  `:lua package.loaded['nvim_mcp.diff'] = nil` (or restart nvim).
- **Build quirks (custom 0.11.6):** an explicit `None` in an `exec_lua`
  args list arrives in Lua as a USERDATA, not nil — guard with
  `type(x) == 'table'`, not truthiness. `:undojoin` joins one pair only
  (no chaining). RPC-injected `<CR>` never fires buffer keymaps (E2E calls
  the keymap callback directly). `nvim_buf_execute`/`execute` with
  dict-args is unsupported. `feedkeys(':w<CR>')` is silently swallowed in
  HEADLESS instances (the command line never processes — use the RPC
  `vim.cmd('write')` in automated tests).
- **Never kill the `server.py` processes** — the daemon does not
  auto-respawn a dead MCP server. Reconnect via `/mcps` in the opencode TUI
  or a session restart.
- **Socket discovery:** this custom nvim build has no `nvim --server-list`;
  `nvim_bridge.discover_socket()` globs `$XDG_RUNTIME_DIR/nvim.<pid>.0`,
  probes each candidate for liveness (sockets linger after death), and
  prefers the instance with a controlling TTY. Mid-review the poll loop is
  **sticky** — a dropped connection returns the "nvim restarted" rejection
  instead of re-discovering, so a review can never wander to a different
  nvim instance (e.g. another one of yours).
- **Stuck-proposal recovery** (only if the poller died mid-review, e.g. this
  opencode session restarted): in nvim, `:lua package.loaded['nvim_mcp.diff']
  = nil` · delete the buffer-local `n` keymaps `<CR>` `ct` `co` `]x` `[x`
  · `vim.api.nvim_buf_clear_namespace` on namespace `nvim_mcp_diff` ·
  `vim.api.nvim_del_augroup_by_name('nvim_mcp_diff')` · restore the buffer
  from disk (`vim.fn.readfile`) · kill the stale Python poller. The next
  `propose_edit` re-renders fresh.

## Limitations

- One proposal at a time (per design); multi-file requests are sequential rounds.
- Target is the TTY-holding nvim; with several interactive instances the
  pick is first-by-mtime (no explicit chooser yet).
- Dirty buffers are rejected, not merged (save first).
- The diff renders in the current window of the target buffer (no floating
  window yet).
