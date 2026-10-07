-- diff.lua: in-buffer review of a proposed edit (NON-BLOCKING design).
--
-- Two entry points, both non-blocking — called from Python over RPC:
--   require('nvim_mcp.diff').render(path, old_str, new_str)
--     -> "rendered"            (proposal on screen, awaiting decision)
--     -> "rejected: ..."       (could not even render, e.g. old_str missing)
--   require('nvim_mcp.diff').decide()
--     -> nil                   (still waiting)
--     -> "accepted"|"rejected" (cleaned up + applied/undone; pending cleared)
--
-- Why non-blocking: a blocking RPC chunk (vim.wait/confirm INSIDE an
-- exec_lua call) permanently wedges this nvim build's event loop —
-- typeahead stops being processed and the TUI freezes (verified live
-- 2026-10-07). The human-in-the-loop therefore lives on the PYTHON side,
-- which polls decide() with small sleeps between RPC calls. While we poll,
-- nvim's main loop is free, so keypresses fire keymaps normally and the
-- UI redraws.
--
-- Decision UX (choice-cursor): the choices are rendered IN the buffer as
-- a single marker line above the proposed change (two lines at both ends
-- read as two alternatives — user feedback 2026-10-07):
--     >>> [a]ccept   [r]eject
--     qux = 200            (red, old text)
--     quux = 300           (green, new text)
-- The buffer is readonly while pending (navigate freely, no accidental
-- edits). ONE buffer-local <CR> keymap decides, and only when the cursor
-- sits on the `a` or `r` character of the marker line — plain a/r/q keys
-- are never mapped, so navigation can no longer decide by accident.

local M = {}

local ns = vim.api.nvim_create_namespace("nvim_mcp_diff")

-- marker line + 0-based columns of the decision characters
local MARKER = ">>> [a]ccept   [r]eject"
local COL_A = MARKER:find("a", 1, true) - 1
local COL_R = MARKER:find("r", 1, true) - 1

vim.api.nvim_set_hl(0, "McpProposalChoice", { link = "Special" })
vim.api.nvim_set_hl(0, "McpProposalKey", { link = "Todo" })

-- module scope: survives across RPC calls (the module loads once)
local pending = nil -- { buf, sl, el, n, top, bottom, ids, prev_mod, opts }
local decided = nil

--- Find old_str in buffer `buf`. Returns {start_line, start_col, end_line, end_col}
--- (0-based, end exclusive) or nil.
local function find_old(buf, old_str)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local full = table.concat(lines, "\n")
    local s = full:find(old_str, 1, true) -- plain find, no patterns
    if not s then return nil end
    local e = s + #old_str - 1
    -- map byte offsets -> (line, col)

    local function to_linecol(off)
        local line, consumed = 0, 0
        for i,l in ipairs(lines) do
            if off <= consumed + #l then
                return i-1, off - consumed
            end
            consumed = consumed + #l +1
            line = i
        end
        return #lines -1, #lines[#lines]
    end
    local sl, sc = to_linecol(s - 1)
    local el, ec = to_linecol(e)
    return {sl, sc, el, ec}
end

--- Paint the proposal and arm the decision keymap. Returns immediately.
function M.render(path, old_str, new_str)
    if pending then
        return "rejected: another proposal is pending"
    end

    -- open the file (current window; task3 may float it)
    local buf = vim.fn.bufnr(path)
    if buf == -1 or not vim.api.nvim_buf_is_valid(buf) then
        vim.cmd("edit " .. vim.fn.fnameescape(path))
        buf = 0
    else
        vim.cmd("buffer " .. buf)
    end

    -- Dirty-buffer guard: on accept the PYTHON side writes disk-based
    -- content, so a buffer whose text diverges from disk would have its
    -- unsaved changes silently clobbered. Reject and ask for :w first.
    -- (A freshly :edit-ed buffer loads from disk, so it is clean by
    -- definition.)
    if vim.bo[buf].modified then
        local buf_text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        local disk = vim.fn.readfile(path)
        if disk == false or buf_text ~= table.concat(disk, "\n") then
            return "rejected: buffer has unsaved changes - save it (:w) and ask the agent again"
        end
    end

    local range = find_old(buf, old_str)
    if not range then
        return "rejected: old_str not found in open buffer (disk changed?)"
    end
    local sl, sc, el, ec = range[1], range[2], range[3], range[4]

    -- Layout after insertion (0-based line numbers):
    --   top  = sl                      marker line
    --   sl+1 .. el+1                   old text (red)
    --   after .. after+n-1             new text (green)
    local new_lines = vim.split(new_str, "\n", { includeempty = true })
    local n = #new_lines
    local top = sl
    vim.api.nvim_buf_set_lines(buf, top, top, false, { MARKER })
    local after = el + 2 -- below the old text (shifted +1 by the marker)
    vim.api.nvim_buf_set_lines(buf, after, after, false, new_lines)

    -- highlights
    local ids = {}
    table.insert(ids, vim.api.nvim_buf_set_extmark(buf, ns, top, 0, {
        end_col = #MARKER, hl_group = "McpProposalChoice",
    }))
    table.insert(ids, vim.api.nvim_buf_set_extmark(buf, ns, top, COL_A, {
        end_col = COL_A + 1, hl_group = "McpProposalKey",
    }))
    table.insert(ids, vim.api.nvim_buf_set_extmark(buf, ns, top, COL_R, {
        end_col = COL_R + 1, hl_group = "McpProposalKey",
    }))
    table.insert(ids, vim.api.nvim_buf_set_extmark(buf, ns, sl + 1, sc, {
        end_line = el + 1, end_col = ec, hl_group = "DiffDelete",
    }))
    table.insert(ids, vim.api.nvim_buf_set_extmark(buf, ns, after, 0, {
        end_line = after + n - 1, end_col = #new_lines[n], hl_group = "DiffAdd",
    }))

    -- readonly while pending: navigate freely, block accidental edits
    -- (which could also destroy the marker lines)
    local prev_mod = vim.bo[buf].modifiable
    vim.bo[buf].modifiable = false

    -- the ONLY decision keymap: <CR> on the a/r character of a marker line
    local opts = { buffer = buf }
    vim.keymap.set("n", "<CR>", function()
        if not pending then return end
        local c = vim.api.nvim_win_get_cursor(0)
        -- this build may return {row, col} or {{row, col}} — unpack defensively
        local row, col = c[1], c[2]
        if type(row) == "table" then row, col = row[1], row[2] end
        local lnum = row - 1
        if lnum ~= pending.top then return end
        local line = vim.api.nvim_buf_get_lines(pending.buf, lnum, lnum + 1, false)[1]
        if col == COL_A and line:sub(col + 1, col + 1) == "a" then
            decided = "accepted"
        elseif col == COL_R and line:sub(col + 1, col + 1) == "r" then
            decided = "rejected"
        end
        -- anywhere else: no-op (proposal stays pending)
    end, opts)

    pending = {
        buf = buf, sl = sl, el = el, n = n, top = top,
        after = after, ids = ids, prev_mod = prev_mod, opts = opts,
    }
    vim.cmd("echo 'nvim-mcp: put cursor on a/r of a choice line, press <CR>'")
    vim.cmd("redraw!") -- force TUI frame; this build's UI lags buffer edits
    return "rendered"
end

--- Non-blocking check. Returns nil while waiting; on a recorded decision,
--- cleans up, applies (accept) or undoes (reject), and returns the decision.
function M.decide()
    if not pending or not decided then
        return nil -- nothing (or still nothing) to report
    end

    local p = pending
    local d = decided
    pending = nil
    decided = nil

    -- cleanup
    for _, id in ipairs(p.ids) do
        vim.api.nvim_buf_del_extmark(p.buf, ns, id)
    end
    vim.keymap.del("n", "<CR>", p.opts)
    vim.bo[p.buf].modifiable = p.prev_mod

    if d == "accepted" then
        -- drop the old text (highest first), then the marker line;
        -- the new text (already in place) becomes the file content
        vim.api.nvim_buf_set_lines(p.buf, p.sl + 1, p.el + 2, false, {})
        vim.api.nvim_buf_set_lines(p.buf, p.top, p.top + 1, false, {})
    else
        -- reject: drop the new text, then the marker line;
        -- buffer back to byte-identical original
        vim.api.nvim_buf_set_lines(p.buf, p.after, p.after + p.n, false, {})
        vim.api.nvim_buf_set_lines(p.buf, p.top, p.top + 1, false, {})
    end
    vim.cmd("redraw!")
    return d
end

return M
