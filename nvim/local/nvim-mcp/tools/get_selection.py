"""get_selection: report the active visual selection in the user's nvim.

Read-only; { active: false } when no visual mode is on (not an error).
The agent should call this when the user says "this", "these lines", or
"the selection" without quoting the text.

The selection RANGE is derived from the bridge's visual-anchor poller
(see nvim_bridge): this nvim build never sets the '< / '> marks and has
no VisualMode event, so the anchor (cursor position at visual entry) is
captured by polling mode + cursor on the Python side.
"""

import json

import nvim_bridge
from tools.current_buffer import current_buffer


def _mode_name(mode: str) -> str:
    return "linewise" if mode == "V" else ("blockwise" if mode == "\x16" else "charwise")


def get_selection() -> str:
    """
    Report the text the user has selected in Neovim (visual mode).

    Call this when the user refers to a selection ("fix this", "rename
    these lines") without quoting the text.

    Returns:
        str: JSON. { active: false } when nothing is selected (not an
        error - fall back to current_buffer). Otherwise { active: true,
        mode: charwise|linewise|blockwise, path, start_line, end_line,
        text } - large selections are truncated to ~200 lines / 8000
        chars and carry truncated: true. range_unknown: true (text: "")
        when the selection was made too fast for the anchor poller.
    """
    try:
        mode, cursor, anchor = nvim_bridge.get_visual_state()
    except Exception as e:  # noqa: BLE001 - clean MCP string, not a traceback
        return f"error: cannot reach nvim ({type(e).__name__}: {e})"

    if mode not in nvim_bridge._VISUAL_MODES:
        return json.dumps({"active": False})

    if anchor is None:
        # Visual entry happened between two poller ticks: no anchor, so the
        # range (and thus the text) can't be derived on this build.
        path = ""
        try:
            path = json.loads(current_buffer()).get("path", "")
        except Exception:  # noqa: BLE001
            pass
        return json.dumps({
            "active": True,
            "range_unknown": True,
            "mode": _mode_name(mode),
            "path": path,
            "line": cursor[0],
            "text": "",
        })

    # pynvim packs the args list as ONE Lua table at `...` — unpack it.
    info = nvim_bridge.run_lua(
        "return require('nvim_mcp').get_selection(table.unpack(...))",
        [mode, list(anchor), list(cursor)],
    )
    if isinstance(info, list):
        info = info[0]
    return json.dumps(info)
