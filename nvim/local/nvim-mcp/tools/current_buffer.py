"""current_buffer: report the buffer the user is looking at.

Read-only query on the FOCUSED window of the attached nvim instance —
what the user is "looking at", not what the agent's cwd suggests. The
agent should call this before propose_edit to target the right file.
"""

import json

import nvim_bridge


def current_buffer() -> str:
    """
    Report which buffer the user is currently viewing in Neovim.

    Call this before proposing an edit when the user refers to "this file",
    "here", or the buffer you are looking at - it tells you the actual
    target instead of guessing from the working directory.

    Returns:
        str: JSON with { path, modified, line, col } of the focused
        window's buffer. path is "" for buffers without a file (scratch,
        terminal, ...) - such a buffer cannot be targeted by propose_edit.
        modified is true when the buffer has unsaved changes (the agent
        should tell the user to save, or account for the divergence).
    """
    try:
        info = nvim_bridge.run_lua(
            "return require('nvim_mcp').current_buffer()", []
        )
        if isinstance(info, list):
            info = info[0]
    except Exception as e:  # noqa: BLE001 - clean MCP string, not a traceback
        return f"error: cannot reach nvim ({type(e).__name__}: {e})"
    return json.dumps(info)
