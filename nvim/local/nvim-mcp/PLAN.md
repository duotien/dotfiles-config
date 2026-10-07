# nvim-mcp — plan (living doc; write-ahead for session compaction)

**Goal:** every file edit the AI agent (opencode) proposes is rendered as a highlighted
diff in the user's nvim buffer; user accepts/rejects there; the agent learns the outcome
and continues. Tracking: `.epic-tasks/nvim-mcp/` (epic.md + task1–3.md).

## Settled architecture (approach B — decided by user)

```
opencode daemon ──MCP stdio (JSON-RPC 2.0, one msg/line)──► .venv/bin/python server.py
   │ spawned on session start, killed on disconnect (no port, no service)
   │
   └─ tool registry: tools/*.py (one file per tool; extensible)
                     │
                     └─ pynvim.attach("socket", path=…) ──msgpack-rpc──► interactive nvim
                                                                           └─ lua/nvim_mcp/diff.lua
                                                                              render() paints + arms a/r/q, returns
                                                                              decide() applies/undoes on keypress
```

- **One long tool call, non-blocking in nvim** — render() returns immediately; PYTHON polls
  decide() every 200 ms until the keypress. (Blocking RPC chunks wedge this build's event
  loop. The single response still carries the decision; the keymap unblocks it.)
- **SSE flake is out of the loop** (this is why we don't intercept `permission.asked`).
- **Agent routing:** agent runs with `edit: deny` + `nvim-mcp_propose_edit: allow` +
  instruction to use `propose_edit` for all file changes → no bypass.
- **Extensible:** the project is a general nvim-as-MCP-server seed (Playwright-MCP pattern).
  Future tools (diagnostics, run_test, buffer state, git) = one Python file each.
  Expansion tracked in `.epic-tasks/backlogs/task-nvim-mcp-expansion.md`.

## Key decisions + rationale (don't re-litigate)

| Decision | Why |
|---|---|
| Python server (not Lua) | user doesn't read Lua; official `mcp` SDK handles protocol + spec drift; tools/testable in pytest. Lua confined to the in-nvim diff module (unavoidable — must run inside nvim) |
| Official `mcp` SDK v2 (not standalone `fastmcp`) | user chose official docs/API; v2 renames FastMCP → `MCPServer` (`from mcp.server import MCPServer`), `mcp.run()` defaults to stdio; sync handlers run on a worker thread (good: pynvim blocking call won't stall the event loop). `pyproject` pin: `mcp>=2.3.0` |
| `pynvim` as bridge | official neovim-org client; `attach("socket")` + `exec_lua()` (sync, returns value, blocks until Lua returns) deletes the hand-rolled msgpack client; bundles msgpack |
| `uv` venv in project dir | system Python untouched; `.venv` gitignored; opencode command points at `.venv/bin/python`; fresh clone = `uv sync` |
| Local plugin layout `nvim/local/nvim-mcp/` | `~/.config/nvim` symlinks into repo → stable abs paths; lazy `dirs = { "local" }` discovers it |
| Name `nvim-mcp` (not nvim-diff-mcp) | platform, not one tool (user chose) |

## Verified facts (empirical / source-read — reuse, don't re-derive)

- **opencode MCP config format** (from user's own playwright entry in
  `~/.config/opencode/opencode.jsonc`):
  ```json
  "mcp": { "servers": { "<name>": { "type": "local", "command": [ … ], "disabled": false } } }
  ```
- **MCP tool permission action (opencode v2):** `<server>_<tool>` → `nvim-mcp_propose_edit`.
  Agent frontmatter (v2 style, like existing `edit-ask.md`):
  `permissions: - action: edit, resource: "*", effect: deny` +
  `- action: nvim-mcp_propose_edit, resource: "*", effect: allow`.
- **Agent files are the agreed exception** to "user-managed opencode config" —
  `~/.config/opencode/agents/*.md` MAY be edited by the agent. `opencode.jsonc` CANNOT —
  prepare a snippet file, user applies.
- **MCP protocol (stdio):** newline-delimited JSON-RPC 2.0. Methods we need:
  `initialize` (respond protocolVersion/capabilities/serverInfo), `notifications/initialized`
  (ignore), `tools/list`, `tools/call` → result `{content:[{type:"text",text}], isError?}`.
  The official `mcp` Python SDK (FastMCP) handles all framing — we just define tools.
- **NInfer (qwen3.8-27b @ :30000, `local` provider in opencode.jsonc):**
  tool-level `strict:true` → 400; plain schemas (additionalProperties:false) → 200 + real
  tool_calls; `tool_choice:"required"` → 400 (unused by us). Parameters are FREELY
  generated (no constrained decoding) → harness parses/validates; our tools validate args.
- **nvim RPC socket discovery (verified live):** this custom build has NO `nvim --server-list`.
  Sockets: `$XDG_RUNTIME_DIR/nvim.<pid>.0` (flat, PID-named); legacy fallback
  `$TMPDIR/nvim.<user>/`. Sockets LINGER after death → liveness probe mandatory. Prefer the
  instance whose PID has a controlling TTY (`/proc/<pid>/stat` tty_nr) — that is the nvim a
  human is looking at (an opencode-spawned `nvim --embed` child in the same project would be
  invisible to the user). Implementation: `nvim_bridge.discover_socket()`.
- opencode.nvim internals (for reference only): SSE 11s watchdog
  (`lua/opencode/server/init.lua` `OPENCODE_HEARTBEAT_INTERVAL_MS=10000`), permission
  autocmds `OpencodeEvent:permission.asked`, `Server:permit(...)` reply endpoint —
  approach A, now abandoned.

## File layout (target)

```
nvim/local/nvim-mcp/
├── PLAN.md                 # this file
├── pyproject.toml          # uv project; deps: mcp, pynvim
├── .venv/                  # gitignored; `uv sync`
├── server.py               # FastMCP app — registry/dispatch only
├── nvim_bridge.py          # discovery + attach cache + run_lua + show_diff poll loop + mark_clean
├── tools/
│   ├── propose_edit.py     # validate → show_diff → disk write on accept (+ mark_clean both ways)
│   └── ping.py             # health + extensibility proof
├── lua/nvim_mcp/
│   ├── init.lua            # lazy local-plugin entry (interactive side)
│   └── diff.lua            # non-blocking render()/decide() (module-scope pending state)
├── opencode.jsonc.snippet  # user-applied mcp.servers entry (applied)
└── README.md               # install/usage/keys/failure modes/dev notes
```

(The Lua iteration scaffold — `server.lua`, `tools/*.lua` — was deleted in task1; `edit-ask.md`
was updated in place, no separate agent-snippet file.)

## Tasks

### task1 (DONE — commit 507771e + d60e1c0; E2E RUN 1 + RUN 2, 4/4 PASS)
1. Write Python scaffold: `pyproject.toml`, `server.py` (FastMCP), `tools/propose_edit.py`
   (validate: file readable, old_str matches exactly once; return placeholder text),
   `tools/ping.py`, `nvim_bridge.py` (stub), rewrite `opencode.jsonc.snippet`
   (command = `[<abs>/.venv/bin/python, <abs>/server.py]`), `AGENT-SNIPPET.md`
   (edit: deny + nvim-mcp_propose_edit allow + routing instruction).
2. Delete Lua scaffold (`server.lua`, `tools/*.lua`).
3. `uv sync` → `.venv`.
4. Wire lazy: `dirs = { "local" }` in `nvim/init.lua`; spec entry in `nvim/lua/plugins/`
   (new `nvim_mcp.lua`) + `plugins.lua` list.
5. Update `~/.config/opencode/agents/edit-ask.md` per snippet (allowed — agent files).
6. Test headless: MCP handshake over a pipe (initialize → tools/list → tools/call
   propose_edit against a scratch file; expect placeholder "accepted"; expect
   "rejected: old_str not found" for bad input). Use `uv run python -c` with a subprocess
   that feeds stdin lines, OR just `printf '…' | .venv/bin/python server.py`.
7. Gate: `zsh -n zsh/.zshenv zsh/.zshrc zsh/alias.sh && nvim --headless +q`.
8. Handoff to user: apply `opencode.jsonc.snippet` block to
   `~/.config/opencode/opencode.jsonc` + restart opencode daemon
   (`opencode serve --service`, port 4096); then real E2E: ask agent to edit a scratch
   file in this repo → it must call `nvim-mcp_propose_edit`.
9. Tick task1 DoD (incl. registry-extensibility: ping proves one-file tools), work log
   Finished stamp, commit, INBOX/INDEX/epic table updates.

### task2 (todo)
`nvim_bridge.py` live: discover socket (`nvim --server-list`), `pynvim.attach`,
`exec_lua("return require('nvim_mcp.diff').show_diff(...)")`. `diff.lua`: open buffer,
render old/new with extmark highlights (delete=DiffDelete-ish, add=DiffAdd-ish), keymaps
a/r (accept-all/reject-all; q=reject), `vim.wait(-1, …)`, on accept write file, return
decision string. propose_edit.py: call bridge; on accept write disk. DoD: N/N in real nvim
from case 2; clean buffer after.

### task3 (IN PROGRESS)
Resilience: stale-connection retry (nvim restart mid-session) + fail-fast clean rejection
(no nvim / restart-during-review) — DONE, live-testing. Dirty-buffer guard in render()
(reject: save first) — DONE, verified. Multi-file = sequential per-file rounds (verify live).
README.md — DONE. PLANS.md sync — in progress.

## Conventions (repo)
- gate: `zsh -n zsh/.zshenv zsh/.zshrc zsh/alias.sh && nvim --headless +q`
- docs_sync: README.md (repo root); commit per task; tracking tick in same commit
- unpushed commits on main so far: c0b73bb, 547eeed, 474a366, 96c3d6b, 9972bd2 (+task1's)
- leave alone: `zsh/.zshenv`, `zsh/.zshrc`, `zsh/alias.sh`, `test.py`,
  `zsh/plugins/zsh-autosuggestions/`
- tmux background-shell convention for long jobs (AGENTS.md): `opencode-` prefixed
  sessions, pipe-pane tee to `.tmp/<name>.log`, `DONE=$?` sentinel

## User workflow notes
- case 1 (TUI conversation) ALSO routes through nvim now — one review surface; TUI native
  diff goes away for the routed agent.
- daemon: `opencode serve --service` port 4096; opencode v2.0.22 at `~/.opencode/bin/opencode`;
  provider `local/qwen3.8-27b` (opencode.jsonc, baseURL 192.168.1.23:30000/v1).
