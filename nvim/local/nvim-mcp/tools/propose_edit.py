"""propose_edit: validate an edit, then show it in nvim for human review.

Validation (disk side): old_str must occur exactly once in the file.
Review (human side): nvim_bridge.show_diff renders the change in the
user's nvim and blocks (on the PYTHON side) until they accept/reject.
On accept the file is written to disk and the nvim buffer's modified
flag is cleared (disk == buffer, no :w needed).
"""

import pathlib

import nvim_bridge


def propose_edit(path: str, old_str: str, new_str: str) -> str:
    """
    Propose an edit to a file.

    Validates that old_str occurs exactly once in the file, then shows
    the change to the user in Neovim for approval.

    Args:
        path (str): The path to the file.
        old_str (str): The string to be replaced.
        new_str (str): The new string to replace the old string.

    Returns:
        str: The user's decision ("Accepted ...") or a rejection reason.
    """
    p = pathlib.Path(path)
    if not p.is_file():
        return f"Rejected: {path} does not exist."
    text = p.read_text()
    n = text.count(old_str)
    if n == 0:
        return "Rejected: old_str not found in the file - read the file first"
    if n > 1:
        return f"Rejected: old_str occurs {n} times - make it more specific"

    decision = nvim_bridge.show_diff(path, old_str, new_str)
    if decision != "accepted":
        if decision == "rejected":
            # True reject: decide() restored the buffer byte-identical to
            # disk, so clear the stale modified flag (no leftover `+`/W12).
            # Pre-render failures ("rejected: <reason>") left the buffer
            # untouched and must keep their flag.
            nvim_bridge.mark_clean(path)
        return decision

    # Python owns the disk write; then sync nvim's modified flag.
    p.write_text(text.replace(old_str, new_str))
    nvim_bridge.mark_clean(path)
    return "Accepted: edit reviewed in nvim and written to disk."
