# Neovim AI plugin notes

Decision record + integration notes for the AI plugin stack.

## Current stack

| Plugin | Status | Gate | Notes |
|---|---|---|---|
| `opencode.nvim` | installed, **default off** | `vim.g.opts.opencode` | talk to the opencode daemon; `<leader>o*` |
| `minuet-ai.nvim` | installed, **default off** | `vim.g.opts.minuet` | ghost text via Ollama 1.5b |
| `avante.nvim` | **planned** (this doc, §3) | would be `vim.g.opts.avante` | inline edit + agentic mode via NInfer |
| `nvim-mcp` | installed (local plugin, §4) | — | Neovim-as-MCP-server; review-gated AI edits |
| `codecompanion.nvim` | **removed** (commit `547eeed`) | — | NInfer `strict` tools 400 killed its file-edit flow; history in `80a991f` |

**Optional-plugin pattern:** `vim.g.opts = { opencode = false, minuet = false }` switchboard at the
top of `nvim/init.lua`; each spec uses `enabled = vim.g.opts.X`, keymaps/which-key groups are
`if`-gated in `core/keymaps.lua` / `plugins/whichkey.lua`. Value is captured at startup →
toggling requires a restart. Fresh clones ship AI-free; `:Lazy sync` re-clones from lockfile pins
on re-enable.

## 1. opencode.nvim — installed

- `<leader>oa` ask / `<leader>ox` select; daemon auto-detect (port 4096 service).
- Edit flow: `edit-ask` agent (`~/.config/opencode/agents/edit-ask.md`, `edit: deny` +
  `nvim-mcp_propose_edit: allow`) → every file edit goes through **nvim-mcp** (§4): in-buffer
  highlighted diff in the user's nvim, one key to accept/reject. (Supersedes the old
  opencode.nvim permission-diff path, which died with the SSE flake below.)
- **Known flake (upstream):** the daemon's SSE heartbeat (10–15 s) races the plugin's
  ~11 s watchdog — the diff tab only appears when the permission event arrives within the
  window. Root cause identified in `lua/opencode/server/init.lua`
  (`OPENCODE_HEARTBEAT_INTERVAL_MS`); chosen path: wait for the upstream fix, then
  `:Lazy update`. Fallback review for tracked files: `git diff`.
- Optional extras (not started): operator prompts, `@gitdiff`/`@gitstatus` contexts,
  `commit` select prompt.

## 2. Minuet — installed & working

- Ollama local, `qwen2.5-coder:1.5b`, virtual-text frontend, `<A-A>` accept.
- Non-obvious config in the spec (why it's shaped this way):
  - **Eager load** — virtualtext gates on a buffer flag set by a `FileType` autocmd; lazy
    `InsertEnter` load leaves buffers opened before the first insert without it.
  - **Native Ollama API** — `/v1/completions` ignores `num_ctx`; a `transform` rewrites to
    `/api/generate` (honors `num_ctx`) with a `no_stream` decoder.
  - **EOF suffix override** — FIM template branch only fires with a non-empty suffix; at EOF
    the empty suffix falls back to the chat template and the model talks instead of completing.
  - **Headless E2E infeasible on this build** (both quirks verified): `vim.fn.mode()` reports
    `'ne'` headless vs `'i'` TUI; extmarks are silently dropped headless. Verified via real
    nvim + the full request pipeline instead.

## 3. Avante — planned (inline edit via NInfer)

Goal: natural-language request → agent decides → file edits shown inline → accept/reject.

**Version pin: `v0.2.3`** — last 0.11-compatible release (2026-08-27). v0.3-rc+ requires
Neovim 0.12 (`vim.net` swap for web_search). Repo is `avante-corp/avante.nvim`
(README badges stale). Missed QoL on v0.3+: tool-schema robustness, `AvanteSwitchProvider
--save`, header model display, RAG/ACP fixes.

**NInfer (:30000, `qwen3.8-27b`) compatibility — verified empirically:**

| Request shape | Result |
|---|---|
| tool-level `strict: true` (CodeCompanion format) | **400** `strict_tools_not_supported` — why CC died |
| `additionalProperties: false` in parameters (avante v0.2.3 `transform_tool` format) | **200**, tool calls generated correctly |
| `tool_choice: "required"` | 400 (unsupported — avante doesn't use it) |
| `:AvanteEdit` (plain inline edit) | tools = nil — no risk at all |

So both `:AvanteEdit` **and** the agentic tool loop are viable against NInfer.

**Planned spec:**
- `vim.g.opts.avante = false` flag; `tag = "v0.2.3"`; `build = "make"` (downloads prebuilt
  Rust binary — needs curl+tar only)
- Provider: `openai` at `http://localhost:30000/v1`, model `qwen3.8-27b`, key via
  `AVANTE_OPENAI_API_KEY` env var
- Mandatory deps: `nui.nvim` + `mega.cmdparse` (+ `mega.logging`); plenary/nvim-cmp/snacks
  already present (plenary pin returns to the lockfile)
- Keymaps: avante auto-binds `<leader>a*` — `<leader>a` prefix is free; no extra keymaps needed
- UX: `auto_approve_tool_permissions` defaults true — set false (or a tool list) to gate edit
  tools behind the permission prompt; prompt logs land in
  `stdpath("cache")/avante_prompts`; `avante.md` for project instructions

## 4. nvim-mcp — installed (local plugin, Python)

Goal: every file edit the agent proposes appears as a highlighted in-buffer diff in the
user's nvim; one key decides; the agent learns the outcome. Full docs:
`nvim/local/nvim-mcp/README.md` (architecture, install, keys, failure modes).

- **Own MCP server** (`server.py`, official `mcp` SDK v2, project venv via uv), spawned per
  opencode session; tool = one Python file (`propose_edit`, `ping`). NOT an interception of
  opencode's `permission.asked` — the SSE 11s watchdog flake (§1) would sit in the critical
  path, v2 permission events no longer carry the patch, and the agent wouldn't learn why a
  review was rejected.
- **Non-blocking review (the key architecture lesson):** a blocking RPC chunk
  (`vim.wait` inside one `exec_lua`) permanently wedges this nvim build's event loop
  (typeahead + TUI die; RPC requests are still answered — that asymmetry is the diagnostic
  signature). So `lua/nvim_mcp/diff.lua` is two non-blocking entry points
  (`render()` paints + arms `a`/`r`/`q`; `decide()` returns nil or the decision), and the
  human-in-the-loop is a 200 ms Python poll loop. nvim's main loop stays free between polls.
- **Socket discovery:** this build has no `nvim --server-list` → glob
  `$XDG_RUNTIME_DIR/nvim.<pid>.0`, probe liveness (sockets linger after death), prefer the
  TTY-holding instance (the one a human is looking at).
- **Safety invariants:** the disk write happens only after a rendered proposal is accepted;
  dirty (unsaved-divergent) buffers are rejected with "save first"; a dead/restarted nvim is
  a clean rejection string, never a traceback; on accept AND on true reject the buffer's
  `modified` flag is cleared (no leftover `+`/W12).
- **Ops:** the daemon does not auto-respawn a killed MCP server — reconnect via `/mcps` in
  the TUI or a session restart; after editing `diff.lua`, clear the require cache
  (`:lua package.loaded['nvim_mcp.diff'] = nil`).
- Status: task1+task2 done (E2E proven from a real edit-ask session), task3 (hardening +
  docs) in progress — `.epic-tasks/nvim-mcp/`.
