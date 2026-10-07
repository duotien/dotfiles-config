"""propose_edit: validate a (multi-hunk) edit, then show it in nvim for review.

Validation (disk side): each hunk's old_text must occur exactly once in the
file, checked SEQUENTIALLY on a working copy (so overlapping/clobbering
hunks fail). Review (human side): nvim_bridge.show_diff renders every hunk
in the user's nvim and blocks (on the PYTHON side) until all are resolved.
On resolution the BUFFER content is written to disk (it may fold in the
user's mid-review edits) and the nvim buffer's modified flag is cleared
(disk == buffer, no :w needed).
"""

import pathlib

import nvim_bridge


def propose_edit(
    path: str,
    old_str: str = "",
    new_str: str = "",
    edits: list[dict] | None = None,
) -> str:
    """
    Propose one or more edits to a file, reviewed in Neovim.

    Use `edits` for multiple parts of the file in one review:
    a list of {"old_text": ..., "new_text": ...} applied in order
    (new_text may be empty to delete). A single legacy `old_str`/`new_str`
    pair is also accepted and treated as a one-hunk edit.

    Validates that each old_text occurs exactly once (sequentially), then
    shows the change(s) to the user in Neovim for per-hunk approval.

    Args:
        path (str): The path to the file to edit.
        old_str (str): Legacy single-hunk: the text to be replaced.
        new_str (str): Legacy single-hunk: the replacement text.
        edits (list): Multi-hunk: [{"old_text": ..., "new_text": ...}, ...].

    Returns:
        str: The resolution summary ("Accepted: resolved: applied=N, ...")
        or a rejection reason.
    """
    if edits is None:
        if not old_str and not new_str:
            return "Rejected: no edit provided (old_str/new_str or edits required)."
        edits = [{"old_text": old_str, "new_text": new_str}]
    if not isinstance(edits, list) or not edits:
        return "Rejected: edits must be a non-empty list of {old_text, new_text}."

    p = pathlib.Path(path)
    if not p.is_file():
        return f"Rejected: {path} does not exist."
    text = p.read_text()
    for i, e in enumerate(edits, 1):
        old, new = e.get("old_text"), e.get("new_text")
        if not isinstance(old, str) or not old:
            return f"Rejected: hunk {i}: old_text must be a non-empty string."
        if not isinstance(new, str):
            return f"Rejected: hunk {i}: new_text must be a string (empty = delete)."
        n = text.count(old)
        if n == 0:
            return f"Rejected: hunk {i}: old_text not found in the file - read the file first"
        if n > 1:
            return f"Rejected: hunk {i}: old_text occurs {n} times - make it more specific"
        text = text.replace(old, new)

    decision = nvim_bridge.show_diff(path, edits)
    if not decision.startswith("resolved"):
        # Pre-render failure ("rejected: <reason>"): the buffer was left
        # untouched by render(), so nothing to clean up on the nvim side.
        return decision

    # Python owns the disk write; the BUFFER is the source of truth (it may
    # include the user's mid-review edits). Skip the write when identical
    # (reject-all / user already saved).
    buf_text = "\n".join(nvim_bridge.get_lines(path))
    disk_text = p.read_text()
    if buf_text != disk_text:
        p.write_text(buf_text + "\n")
        nvim_bridge.mark_clean(path)
    return f"Accepted: {decision} - buffer written to disk."
