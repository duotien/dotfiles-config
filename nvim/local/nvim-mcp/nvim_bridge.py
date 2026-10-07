"""Bridge from this MCP server to the interactive nvim, via pynvim.

One review round-trip per proposed multi-hunk edit: render() paints all
hunks in the user's nvim and returns; Python then polls decide() until
every hunk is resolved — the human-in-the-loop lives on the PYTHON side
because a blocking RPC chunk wedges this nvim build's event loop (see
diff.lua header).

Socket discovery: our custom nvim build lacks `nvim --server-list`, so we
glob the RPC socket dir, probe each candidate for liveness (sockets linger
after an instance dies), and prefer instances with a controlling TTY —
that is the nvim a human is looking at.

Resilience (task3): the MCP server process outlives nvim restarts, so the
cached connection can go stale — run_lua drops it on a transport error and
re-attaches once. Mid-review the poll loop is STICKY (no re-discovery): a
dropped connection is a clean "nvim restarted" rejection, never a wander to
a different instance. show_diff never raises: a missing/unreachable nvim
(or a restart during review, which loses the pending state) is a clean
rejection string the agent can report. The disk write in propose_edit is
gated behind a successful render, so no failure path can write blindly.
"""

import glob
import os
import socket as _socket
import tempfile
import threading
import time
from typing import Any

import pynvim

_nvim = None
_nvim_path = None
_nvim_is_tty = False
# pynvim's sync session is not thread-safe; the visual-anchor poller thread
# shares it with tool calls, so serialize every RPC.
_rpc_lock = threading.Lock()

# task3 fix 2: Lua<->Python protocol handshake. Bump PROTOCOL_VERSION in
# lockstep with lua/nvim_mcp/init.lua's M.VERSION whenever a call shape
# changes; the bridge compares them on attach and fails loudly on drift. A
# stale server process (old Python, fresh Lua) would otherwise give a
# cryptic reject like "edits must be a non-empty list".
PROTOCOL_VERSION = 1


class StaleProtocol(RuntimeError):
    """The running MCP server's Python is out of sync with the Lua module."""


def _pid_of(path: str) -> int:
    """Socket path nvim.<pid>.0 -> pid."""
    return int(path.rsplit("/", 1)[1].rsplit(".", 2)[1])


def _has_tty(pid: int) -> bool:
    """True if the process has a controlling terminal (is interactive)."""
    try:
        with open(f"/proc/{pid}/stat") as f:
            # comm (field 2) is parenthesized and may contain spaces; split after it
            data = f.read().rsplit(")", 1)[1].split()
            return int(data[4]) > 0  # tty_nr is field 7 overall, index 4 after comm
    except (OSError, ValueError, IndexError):
        return False


def discover_socket() -> str:
    """Locate a LIVE, PREFERABLY INTERACTIVE RPC socket.

    Sockets linger after a nvim instance dies, so mtime alone lies: probe
    each candidate with a real connect and only keep ones that answer.
    Layout: $XDG_RUNTIME_DIR/nvim.<pid>.0 (flat, modern); fallback to the
    legacy $TMPDIR/nvim.<user>/ tree.

    Among live sockets, prefer instances with a controlling TTY — that is
    the nvim a human is looking at. Headless/embedded instances (e.g. an
    opencode-spawned `nvim --embed` child in the same project) would be
    invisible to the user and are a wrong target.
    """
    patterns = [
        os.path.join(os.environ.get("XDG_RUNTIME_DIR", ""), "nvim.*.0"),
    ]
    base = os.path.join(tempfile.gettempdir(), f"nvim.{os.environ.get('USER', '')}")
    patterns += [base + "/*", base + "/*/*"]
    candidates = [
        p for pattern in patterns
        for p in glob.glob(pattern)
        if os.path.exists(p)
    ]
    live = []
    for path in sorted(candidates, key=os.path.getmtime, reverse=True):
        probe = _socket.socket(_socket.AF_UNIX, _socket.SOCK_STREAM)
        try:
            probe.connect(path)
            live.append(path)
        except OSError:
            pass
        finally:
            probe.close()
    if not live:
        raise RuntimeError("No running neovim instance found (no live RPC socket)")
    interactive = [p for p in live if _has_tty(_pid_of(p))]
    return (interactive or live)[0]


def attach():
    """Connect once; the MCP server process lives across tool calls, so reuse the connection instead of re-attaching per call."""
    global _nvim, _nvim_path, _nvim_is_tty
    if _nvim is None:
        _nvim_path = discover_socket()
        _nvim_is_tty = _has_tty(_pid_of(_nvim_path))
        _nvim = pynvim.attach("socket", path=_nvim_path)
        _check_version(_nvim)
    return _nvim


def _check_version(nvim) -> None:
    """task3 fix 2: verify the Lua module speaks the same protocol version.

    A mismatch means the running MCP server process is STALE (its Python was
    loaded before a Lua edit) — surface an explicit restart message instead of
    letting a drifted call shape produce a cryptic reject. A version-read
    failure is not fatal (don't block attach on it).
    """
    try:
        got = nvim.exec_lua("return require('nvim_mcp').VERSION", [])
    except Exception:  # noqa: BLE001
        return
    if got != PROTOCOL_VERSION:
        raise StaleProtocol(
            "MCP server is stale vs the nvim Lua module "
            f"(protocol {got} != {PROTOCOL_VERSION}) - restart the opencode "
            "service (opencode service restart) so the server reloads this Python"
        )


def ensure_attached():
    """attach() plus task3 fix 1: per-call target re-verification.

    If the current connection is to a NON-interactive instance (headless /
    --embed child) and an interactive TTY instance now exists, migrate to it.
    The one-shot cached attach (fix 1's amplifier) otherwise sticks to the
    first instance forever even after the user's real nvim appears (the
    transport never dies, so no re-discovery fires). Migration is
    one-directional (non-TTY -> TTY): we NEVER swap between two live TTYs
    (surprise) nor fall TTY -> non-TTY. Mid-review code must NOT call this —
    it uses _exec_lua(allow_rediscovery=False) directly.
    """
    if _nvim is None:
        return attach()
    if not _nvim_is_tty:
        try:
            target = discover_socket()
        except RuntimeError:
            return _nvim  # no live instance; keep (death handled by run_lua)
        if _has_tty(_pid_of(target)) and target != _nvim_path:
            invalidate()
            return attach()
    return _nvim


def invalidate() -> None:
    """Drop a (possibly dead) cached connection; next attach() re-discovers."""
    global _nvim, _nvim_path, _nvim_is_tty
    _nvim = None
    _nvim_path = None
    _nvim_is_tty = False


def run_lua(code: str, args: list) -> Any:
    try:
        return _exec_lua(code, args)
    except OSError:
        # Transport-level failure (e.g. user restarted nvim, socket died):
        # drop the cache, rediscover, retry ONCE. Lua-level errors (pynvim
        # raises nvim.error, not OSError) are NOT retried — re-running a
        # half-executed render could double-apply it.
        invalidate()
        return _exec_lua(code, args)


def _exec_lua(code: str, args: list, allow_rediscovery: bool = True) -> Any:
    """run_lua core. With allow_rediscovery=False a transport failure raises
    instead of re-attaching via discovery — mid-review the poll loop must
    NEVER wander to a different (e.g. the user's other) instance: the
    pending state lives in the rendered instance's module scope, and a
    re-discovery that lands elsewhere would poll the wrong nvim's decide().
    """
    if not allow_rediscovery:
        if _nvim is None:
            raise OSError("nvim connection lost")
        nvim = _nvim
    else:
        nvim = ensure_attached()
    with _rpc_lock:
        return nvim.exec_lua(code, args)


# ---------------------------------------------------------------------------
# Visual-mode tracking (get_selection tool).
#
# BUILD QUIRK: this custom 0.11.6 build never sets the '< / '> marks during
# (or after) visual mode — getpos("'<") is {0,0,0,0} even with real
# keystrokes (verified live) — and the VisualMode/ModeChanged autocmd
# events do not exist, so nothing inside nvim can tell us when a selection
# STARTED. The only missing piece of a selection is that start (the cursor
# end moves and IS observable). So we poll mode + cursor at ~10 Hz and
# capture the cursor position at the non-visual → visual transition: that
# is the anchor. A human selection always spans more than one tick; if one
# doesn't, get_selection degrades to range_unknown.
_VISUAL_MODES = ("v", "V", "\x16")  # charwise, linewise, blockwise
_visual_lock = threading.Lock()
_visual_anchor: tuple[int, int] | None = None
_anchor_conn: str | None = None


def _mode_cursor() -> tuple[str, int, int]:
    """(mode, line, col0) of the focused window, fresh RPC read."""
    result = run_lua(
        "return { vim.fn.mode(), table.unpack(vim.api.nvim_win_get_cursor(0)) }",
        [],
    )
    return result[0], result[1], result[2]


def _mode_poll_loop() -> None:
    global _visual_anchor, _anchor_conn
    while True:
        time.sleep(0.1)
        try:
            mode, line, col = _mode_cursor()
        except Exception:
            # Unreachable nvim (restarted, closed): nothing to track; the
            # next successful tick re-enters from scratch (anchor starts nil).
            with _visual_lock:
                _visual_anchor = None
                _anchor_conn = None
            continue
        with _visual_lock:
            if mode in _VISUAL_MODES:
                if _visual_anchor is None:
                    _visual_anchor = (line, col)
                    _anchor_conn = _nvim_path
            else:
                _visual_anchor = None
                _anchor_conn = None


def start_poller() -> None:
    """Start the visual-anchor poller (idempotent per process; server.py
    calls it at import). Daemon thread — dies with the MCP server."""
    threading.Thread(
        target=_mode_poll_loop, name="nvim-mcp-visual-anchor", daemon=True
    ).start()


def get_visual_state() -> tuple[str, tuple[int, int], tuple[int, int] | None]:
    """(mode, cursor, anchor) with a FRESH mode/cursor read.

    The anchor is only valid if it was captured on the CURRENT instance —
    after a reconnect to a different socket a stale anchor would describe
    a selection in a dead nvim.
    """
    mode, line, col = _mode_cursor()
    with _visual_lock:
        anchor = _visual_anchor
        same_instance = _anchor_conn is not None and _anchor_conn == _nvim_path
    return mode, (line, col), (anchor if same_instance else None)


def mark_clean(path: str) -> None:
    """After the Python side wrote the file, tell nvim disk == buffer.

    Clears the modified flag on the buffer showing `path` so the user
    never has to :w — the agent's flow owns the disk.
    """
    run_lua(
        """
        local arg = table.unpack(...)
        local buf = vim.fn.bufnr(arg)
        if buf ~= -1 and vim.api.nvim_buf_is_valid(buf)
           and vim.api.nvim_buf_get_name(buf) == arg then
            vim.bo[buf].modified = false
        end
        """,
        [path],
    )


def get_lines(path: str) -> list:
    """Buffer content for `path` as a line list (nvim_buf_get_lines).

    After a resolved review the BUFFER is the source of truth (it may fold
    in the user's mid-review edits), so the disk write uses this, not the
    proposed text. Returns [] if the buffer is not open.
    """
    lines = run_lua(
        """
        local path = table.unpack(...) -- single-arg list: the arg itself
        local buf = vim.fn.bufnr(path)
        if buf == -1 or not vim.api.nvim_buf_is_valid(buf) then return {} end
        return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        """,
        [path],
    )
    return lines or []


def show_diff(path: str, edits: list) -> str:
    """Render the proposed multi-hunk edit in nvim; block (PYTHON side) until
    every hunk is resolved.

    `edits` is a list of {"old_text": ..., "new_text": ...}.
    Never raises: a missing/unreachable nvim is a clean rejection string the
    agent can report (and the disk write in propose_edit is gated behind a
    successful render, so no failure path can write blindly).
    """
    try:
        # pynvim packs the args list as ONE Lua table at `...`; unpack it.
        state = run_lua(
            "return require('nvim_mcp.diff').render(table.unpack(...))",
            [path, edits],
        )
        if state != "rendered":
            return state
        # The pending diff lives in THIS instance's module scope. If nvim
        # restarts mid-review, run_lua transparently re-attaches to a fresh
        # instance whose pending is nil — decide() would then poll forever.
        # Detect it by SOCKET PATH and by nvim PID (a restart on the same
        # socket path keeps the path but changes the pid).
        render_socket = _nvim_path
        render_pid = run_lua("return vim.fn.getpid()", [])
        # Human-in-the-loop, but on OUR side: poll with small non-blocking
        # RPC calls. nvim's main loop stays free between polls, so keypresses
        # fire keymaps normally and the UI redraws. (Blocking RPC chunks
        # wedge this build's event loop — see diff.lua header.)
        # The polling RPCs are STICKY: on a transport failure we reject
        # immediately instead of re-attaching via discovery. Discovery
        # prefers TTY instances, so a mid-review reconnect could wander to
        # a different nvim (e.g. the user's other instance) whose module
        # has no pending state — decide() would then poll nil forever, or
        # worse, commands would run in the wrong instance.
        REJECT_RESTART = "rejected: nvim restarted during review - please re-run the edit"
        while True:
            time.sleep(0.2)
            if _nvim_path != render_socket:
                return REJECT_RESTART
            try:
                if _exec_lua("return vim.fn.getpid()", [], allow_rediscovery=False) != render_pid:
                    return REJECT_RESTART
                decision = _exec_lua(
                    "return require('nvim_mcp.diff').decide()", [], allow_rediscovery=False
                )
            except OSError:
                invalidate()
                return REJECT_RESTART
            if decision is not None:
                return decision
    except StaleProtocol as e:
        invalidate()
        return str(e)
    except Exception as e:  # noqa: BLE001 - surface a clean MCP string, not a traceback
        invalidate()
        return f"rejected: cannot reach nvim ({type(e).__name__}: {e})"
