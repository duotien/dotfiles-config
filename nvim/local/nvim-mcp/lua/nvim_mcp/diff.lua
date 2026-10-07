-- diff.lua: in-buffer review of a proposed MULTI-HUNK edit (NON-BLOCKING).
--
-- Two entry points, both non-blocking — called from Python over RPC:
--   require('nvim_mcp.diff').render(path, edits)
--     edits = { { old_text = "...", new_text = "..." }, ... }
--     -> "rendered"            (proposal on screen, awaiting decisions)
--     -> "rejected: ..."       (could not even render; buffer untouched)
--   require('nvim_mcp.diff').decide()
--     -> nil                   (any hunk still unresolved)
--     -> "resolved: applied=N, rejected=M"  (cleaned up; pending cleared)
--     -> "resolved: user-saved, N unresolved..." (:w mid-review ENDS the
--                               session — the buffer the user saved IS the
--                               file; remaining choice lines are stripped)
--     -> "aborted: ..."        (undo/external change disturbed the review;
--                               nothing was written)
--
-- Why non-blocking: a blocking RPC chunk (vim.wait/confirm INSIDE an
-- exec_lua call) permanently wedges this nvim build's event loop —
-- typeahead stops being processed and the TUI freezes (verified live
-- 2026-10-07). The human-in-the-loop therefore lives on the PYTHON side,
-- which polls decide() with small sleeps between RPC calls. While we poll,
-- nvim's main loop is free, so keypresses fire keymaps normally and the
-- UI redraws.
--
-- Decision UX (avante-style, 2026-10-07): each hunk renders as
--     >>> [a]ccept   [r]eject      choice line (real line, per hunk)
--     [ghost] old line              old text as virt_lines (virtual only)
--     new line                      new text as REAL buffer lines
-- The buffer stays EDITABLE (readonly guard removed): mid-review edits are
-- folded into the disk write, which the PYTHON side performs on "resolved"
-- using the buffer content. Two decision styles per hunk:
--   <CR> with cursor on that hunk's `a`/`r` letter (safe: bare a/r are
--   NEVER mapped — the choice-line guarantee from the cursor epic), and
--   cursor-follow fast keys `ct`/`co`, which act on the hunk CONTAINING the
--   cursor (choice line or new lines); a no-op anywhere else.
-- Navigation: `]x`/`[x` walk to the next/previous UNRESOLVED hunk (wrapped,
-- centered); after each decision the cursor auto-jumps to the next
-- unresolved hunk. Render lands the cursor on the first hunk.
--
-- Build quirks (custom 0.11.6): virt_lines chunks must each be wrapped in
-- their own array ({ { {text, hl} } }); nvim_win_get_cursor may return the
-- position as a nested table (defensive unpack); nvim_buf_get_extmarks
-- requires the 5th opts arg; no nvim_buf_clear_extmarks (loop over ids).

local M = {}

local ns = vim.api.nvim_create_namespace("nvim_mcp_diff")
local AUG = "nvim_mcp_diff" -- autocmd group (BufWritePost: :w ends the review)

local MARKER = ">>> [a]ccept   [r]eject"
local COL_A = MARKER:find("a", 1, true) - 1
local COL_R = MARKER:find("r", 1, true) - 1

vim.api.nvim_set_hl(0, "McpProposalChoice", { link = "Special" })
vim.api.nvim_set_hl(0, "McpProposalKey", { link = "Todo" })
vim.api.nvim_set_hl(0, "McpGhostOld", { link = "DiffDelete" })

-- module scope: survives across RPC calls (the module loads once)
local pending = nil -- { buf, hunks = { hunk, ... }, km = { buffer = buf } }

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
        for i, l in ipairs(lines) do
            if off <= consumed + #l then
                return i - 1, off - consumed
            end
            consumed = consumed + #l + 1
            line = i
        end
        return #lines - 1, #lines[#lines]
    end
    local sl, sc = to_linecol(s - 1)
    local el, ec = to_linecol(e)
    return { sl, sc, el, ec }
end

--- Cursor line (0-based) with defensive unpack (nested-table quirk).
local function cursor_line()
    local c = vim.api.nvim_win_get_cursor(0)
    local row = c[1]
    if type(row) == "table" then row = row[1] end
    return row - 1
end

local function hunk_contains(h, lnum)
    if h.resolved then return false end
    if lnum == h.sl then return true end -- choice line
    return h.count > 0 and lnum >= h.start and lnum < h.start + h.count
end

--- Unresolved hunk at the cursor, or nil.
local function hunk_at_cursor(p)
    local lnum = cursor_line()
    for i, h in ipairs(p.hunks) do
        if hunk_contains(h, lnum) then return h, i end
    end
    return nil
end

--- Shift the stored line numbers of hunks after `idx` by `delta`.
local function shift(p, idx, delta)
    if delta == 0 then return end
    for j = idx + 1, #p.hunks do
        p.hunks[j].sl = p.hunks[j].sl + delta
        p.hunks[j].start = p.hunks[j].start + delta
    end
end

--- Place the cursor on hunk `i`'s choice line, centered.
local function jump_to(p, i)
    local h = p.hunks[i]
    if not h or h.resolved then return end
    vim.api.nvim_win_set_cursor(0, { h.sl + 1, 0 })
    vim.cmd("normal! zz")
end

--- Next unresolved hunk after index `from` walking `dir` (+1/-1), wrapping;
--- nil when nothing is unresolved.
local function next_unresolved(p, from, dir)
    local n = #p.hunks
    local i = from
    for _ = 1, n do
        i = i + dir
        if i > n then i = 1 end
        if i < 1 then i = n end
        if not p.hunks[i].resolved then return i end
    end
    return nil
end

--- `]x` / `[x`: walk from the cursor to the next/prev UNRESOLVED hunk
--- (resolved hunks are skipped; wraps around; no-op when none left).
local function nav(p, dir)
    local lnum = cursor_line()
    local n = #p.hunks
    local start
    if dir == 1 then
        for i = n, 1, -1 do
            if not p.hunks[i].resolved and p.hunks[i].sl <= lnum then
                start = i
                break
            end
        end
        start = start or 0 -- above all hunks: wrap from the end
    else
        for i = 1, n do
            if not p.hunks[i].resolved and p.hunks[i].sl >= lnum then
                start = i
                break
            end
        end
        start = start or (n + 1) -- below all hunks: wrap from the start
    end
    local i = start
    for _ = 1, n do
        i = i + dir
        if i > n then i = 1 end
        if i < 1 then i = n end
        if not p.hunks[i].resolved then
            jump_to(p, i)
            return
        end
    end
end

--- Resolve hunk `i` as "applied" or "rejected".
-- Region after render: choice line + new lines (old lines are GONE from the
-- real buffer at render time — they live only in the ghost).
-- applied: drop the choice line; new lines become plain content.
-- rejected: restore old lines, then drop the choice line.
local function resolve(p, i, action)
    local h = p.hunks[i]
    if h.resolved then return end
    -- Sanity guard: an undo/redo (or external change) mid-review desyncs the
    -- stored line numbers and drops the extmarks. Detect it via the choice
    -- line text and abort cleanly instead of deciding on stale positions.
    local line = vim.api.nvim_buf_get_lines(p.buf, h.sl, h.sl + 1, false)[1]
    if line ~= MARKER then
        h.resolved = "aborted"
        return
    end
    vim.api.nvim_buf_del_extmark(p.buf, ns, h.ghost_id)
    if h.hl_id then
        vim.api.nvim_buf_del_extmark(p.buf, ns, h.hl_id)
    end
    if action == "applied" then
        vim.api.nvim_buf_set_lines(p.buf, h.sl, h.sl + 1, false, {})
        shift(p, i, -1)
    else
        vim.api.nvim_buf_set_lines(p.buf, h.sl, h.sl + h.count, false, h.old_lines)
        vim.api.nvim_buf_set_lines(p.buf, h.sl + #h.old_lines, h.sl + #h.old_lines + 1, false, {})
        shift(p, i, #h.old_lines - 1 - h.count)
    end
    h.resolved = action
    -- Undo granularity (documented limitation of this build): the render is
    -- ONE undo unit (all mutations in one RPC stage), but each decision is
    -- its own unit — `:undojoin` only joins a single pair here and cannot
    -- chain onto an already-joined entry (verified with a minimal probe).
    -- `u` therefore steps back one decision at a time, which also lets the
    -- user undo an individual decision.
    local j = next_unresolved(p, i, 1)
    if j then
        jump_to(p, j)
    end
end

--- Paint all hunks and arm the decision keymaps. Returns immediately.
function M.render(path, edits)
    if pending then
        return "rejected: another proposal is pending"
    end
    if type(edits) ~= "table" or #edits == 0 then
        return "rejected: edits must be a non-empty list of {old_text, new_text}"
    end

    -- open the file (current window)
    local buf = vim.fn.bufnr(path)
    if buf == -1 or not vim.api.nvim_buf_is_valid(buf) then
        vim.cmd("edit " .. vim.fn.fnameescape(path))
        buf = 0
    else
        vim.cmd("buffer " .. buf)
    end

    -- Dirty-buffer guard: on resolve the PYTHON side writes buffer content,
    -- so a buffer whose text diverges from disk would commit unsaved work
    -- silently. Reject and ask for :w first. (A freshly :edit-ed buffer
    -- loads from disk, so it is clean by definition.)
    local disk_lines = vim.fn.readfile(path)
    if disk_lines == false then
        return "rejected: cannot read " .. path .. " from disk"
    end
    if vim.bo[buf].modified then
        local buf_text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        if buf_text ~= table.concat(disk_lines, "\n") then
            return "rejected: buffer has unsaved changes - save it (:w) and ask the agent again"
        end
    end

    -- Match every hunk up front against the DISK state (all-or-nothing:
    -- no partial render if a later hunk fails).
    local disk_text = table.concat(disk_lines, "\n")
    local matches = {}
    for i, e in ipairs(edits) do
        local m = find_old(buf, e.old_text)
        if not m then
            return string.format("rejected: hunk %d: old_text not found in open buffer (disk changed?)", i)
        end
        matches[i] = m
    end

    local km = { buffer = buf }
    local hunks = {}
    -- Render sequentially on the live buffer. Positions come from the DISK
    -- matches + a running offset: a live re-search would re-match inside
    -- previously inserted choice lines (MARKER contains "a", "c", "e", ...)
    -- and corrupt the hunk layout. The buffer equals disk here (dirty
    -- guard), so disk offsets + insertions from earlier hunks are exact.
    local offset = 0
    for i, e in ipairs(edits) do
        local m = matches[i]
        local sl, el = m[1] + offset, m[3] + offset
        local old_lines = vim.api.nvim_buf_get_lines(buf, sl, el + 1, false)
        -- "" = pure delete: vim.split("", ...) would yield {""} (one real
        -- empty line) — special-case it to zero lines.
        local new_lines = e.new_text == "" and {}
            or vim.split(e.new_text, "\n", { includeempty = true })
        local count = #new_lines

        offset = offset + (1 + count - #old_lines) -- choice line + net replace

        -- replace old span with new lines, insert choice line above
        vim.api.nvim_buf_set_lines(buf, sl, el + 1, false, new_lines)
        vim.api.nvim_buf_set_lines(buf, sl, sl, false, { MARKER })

        -- ghost old lines below the choice line (virtual, not real text);
        -- build quirk: each chunk wrapped in its own array
        local ghost = {}
        for _, l in ipairs(old_lines) do
            table.insert(ghost, { { l, "McpGhostOld" } })
        end
        local h = { sl = sl, count = count, old_lines = old_lines, resolved = nil }
        h.ghost_id = vim.api.nvim_buf_set_extmark(buf, ns, sl, 0, {
            virt_lines = ghost,
            virt_lines_above = false,
            hl_mode = "combine",
        })
        h.start = sl + 1
        if count > 0 then
            h.hl_id = vim.api.nvim_buf_set_extmark(buf, ns, sl + 1, 0, {
                end_line = sl + count,
                hl_group = "DiffAdd",
                hl_mode = "combine",
            })
        else
            h.hl_id = nil
        end
        hunks[#hunks + 1] = h
    end

    -- decision keymaps (buffer-local, normal mode). Bare a/r are NEVER
    -- mapped; the letters only matter under <CR> on a choice line.
    local opts = km
    vim.keymap.set("n", "<CR>", function()
        if not pending then return end
        local c = vim.api.nvim_win_get_cursor(0)
        local row, col = c[1], c[2]
        if type(row) == "table" then row, col = row[1], row[2] end
        local lnum = row - 1
        for i, h in ipairs(pending.hunks) do
            if lnum == h.sl then
                local line = vim.api.nvim_buf_get_lines(pending.buf, lnum, lnum + 1, false)[1]
                if col == COL_A and line:sub(col + 1, col + 1) == "a" then
                    resolve(pending, i, "applied")
                elseif col == COL_R and line:sub(col + 1, col + 1) == "r" then
                    resolve(pending, i, "rejected")
                end
                return -- on a choice line but not on a letter: no-op
            end
        end
    end, opts)
    vim.keymap.set("n", "ct", function()
        if not pending then return end
        local h, i = hunk_at_cursor(pending)
        if h then resolve(pending, i, "applied") end
    end, opts)
    vim.keymap.set("n", "co", function()
        if not pending then return end
        local h, i = hunk_at_cursor(pending)
        if h then resolve(pending, i, "rejected") end
    end, opts)
    vim.keymap.set("n", "]x", function()
        if pending then nav(pending, 1) end
    end, opts)
    vim.keymap.set("n", "[x", function()
        if pending then nav(pending, -1) end
    end, opts)

    -- :w mid-review ENDS the session: the buffer the user saved IS the file.
    -- decide() then strips remaining choice lines and returns a user-saved
    -- summary; Python skips the disk write (buffer == disk).
    local ag = vim.api.nvim_create_augroup(AUG, { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
        buffer = buf,
        group = ag,
        callback = function()
            if pending and pending.buf == buf then
                pending.user_saved = true
            end
        end,
    })

    pending = { buf = buf, hunks = hunks, km = km }
    vim.api.nvim_win_set_cursor(0, { hunks[1].sl + 1, 0 }) -- first hunk
    vim.cmd("echo 'nvim-mcp: " .. #hunks .. " hunk(s) pending - [a]/[r]+<CR> on a choice line, ct/co at a hunk, ]x/[x to walk'")
    vim.cmd("redraw!") -- force TUI frame; this build's UI lags buffer edits
    return "rendered"
end

--- Non-blocking check. Returns nil while any hunk is unresolved (and no
--- :w happened); when all are resolved — or the user saved mid-review —
--- cleans up and returns the summary string.
function M.decide()
    local p = pending
    if not p then
        return nil
    end
    local all_resolved = true
    for _, h in ipairs(p.hunks) do
        if not h.resolved then
            all_resolved = false
            break
        end
    end
    if not (all_resolved or p.user_saved) then
        return nil -- still waiting
    end

    -- User saved mid-review: the remaining (unresolved) hunks are kept
    -- AS SHOWN — their new lines stay, but the choice lines must not reach
    -- disk. Strip by CONTENT (full-buffer scan), not stored positions:
    -- mid-review user edits shift lines, and a position-based strip leaks
    -- the moved markers to disk (live-reproduced 2026-10-07). MARKER is
    -- scaffolding; a user line that happens to equal it verbatim is a
    -- documented 1-in-a-million edge.
    if p.user_saved then
        local lines = vim.api.nvim_buf_get_lines(p.buf, 0, -1, false)
        local kept = {}
        for _, l in ipairs(lines) do
            if l ~= MARKER then kept[#kept + 1] = l end
        end
        if #kept ~= #lines then
            vim.api.nvim_buf_set_lines(p.buf, 0, -1, false, kept)
        end
    end

    pending = nil
    pcall(vim.keymap.del, "n", "<CR>", p.km)
    pcall(vim.keymap.del, "n", "ct", p.km)
    pcall(vim.keymap.del, "n", "co", p.km)
    pcall(vim.keymap.del, "n", "]x", p.km)
    pcall(vim.keymap.del, "n", "[x", p.km)
    pcall(vim.api.nvim_del_augroup_by_name, AUG)
    vim.api.nvim_buf_clear_namespace(p.buf, ns, 0, -1)

    local a, r, ab, un = 0, 0, 0, 0
    for _, h in ipairs(p.hunks) do
        if h.resolved == "applied" then a = a + 1
        elseif h.resolved == "rejected" then r = r + 1
        elseif h.resolved == "aborted" then ab = ab + 1
        else un = un + 1 end
    end
    vim.cmd("redraw!")
    if ab > 0 then
        return "aborted: review disturbed (undo?) - nothing written"
    end
    if p.user_saved then
        return string.format(
            "resolved: user-saved, %d unresolved hunk(s) kept as shown - buffer is the file",
            un)
    end
    return string.format("resolved: applied=%d, rejected=%d", a, r)
end

return M
