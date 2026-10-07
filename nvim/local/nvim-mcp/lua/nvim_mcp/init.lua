-- nvim-mcp: Neovim side of the MCP server exposing nvim to AI agents (opencode).
--
-- The agent-facing server is server.py (Python, stdio), spawned on demand by
-- the agent daemon (see opencode.jsonc.snippet). This module hosts the
-- read-only UI-state queries (current_buffer / get_selection); the in-buffer
-- diff review lives in nvim_mcp.diff.
local M = {}

-- Protocol version shared with the Python bridge (task3 fix 2). Bump in
-- lockstep with nvim_bridge.PROTOCOL_VERSION whenever any Python<->Lua call
-- shape changes; the bridge checks it on attach and fails loudly ("MCP server
-- stale, restart") on drift instead of a cryptic reject.
M.VERSION = 1

function M.setup() end

---@param text string
---@param max_lines integer
---@param max_chars integer
---@return string text, boolean truncated
function M._truncate(text, max_lines, max_chars)
    local lines = vim.split(text, "\n", { includeempty = true })
    local truncated = false
    if #lines > max_lines then
        local cut = {}
        for i = 1, max_lines do
            cut[#cut + 1] = lines[i]
        end
        lines = cut
        truncated = true
    end
    local out = table.concat(lines, "\n")
    if #out > max_chars then
        out = out:sub(1, max_chars)
        truncated = true
    end
    if truncated then
        out = out .. "\n... (truncated)"
    end
    return out, truncated
end

---The buffer the user is looking at (focused window), for the MCP
---`current_buffer` tool.
---@return { path: string, modified: boolean, line: integer, col: integer }
function M.current_buffer()
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local pos = vim.api.nvim_win_get_cursor(0)
    return {
        -- "" for no-file buffers (scratch, terminal, ...); the agent should
        -- treat that as "not targetable by propose_edit".
        path = name ~= "" and vim.fn.resolve(vim.fn.fnamemodify(name, ":p")) or "",
        modified = vim.bo[buf].modified,
        line = pos[1],
        col = pos[2],
    }
end

-- BUILD QUIRK: on this custom 0.11.6 build the '< / '> marks are NEVER set
-- during (or after) visual mode — getpos("'<") returns {0,0,0,0} even with
-- real keystrokes (verified live) — and the VisualMode/ModeChanged autocmd
-- events do not exist. So the visual ANCHOR is tracked on the PYTHON side
-- (nvim_bridge polls mode + cursor and captures the cursor position at
-- visual entry); get_selection is a pure function of (mode, anchor, cursor).

---Extract a selection range as a line list.
---1-based inclusive line numbers; `scol`/`ecol` are 1-based and INCLUSIVE
---(for blockwise too). Linewise ignores columns (pass 0).
---@param buf integer
---@param sl integer
---@param scol integer
---@param el integer
---@param ecol integer
---@param mode string 'v' | 'V' | '\22'
---@return string[]
function M._extract(buf, sl, scol, el, ecol, mode)
    local lo, hi = math.min(sl, el), math.max(sl, el)
    local lines
    if mode == "V" then
        lines = vim.api.nvim_buf_get_lines(buf, lo - 1, hi, false)
    elseif mode == "\22" then
        local c1, c2 = math.min(scol, ecol), math.max(scol, ecol)
        local raw = vim.api.nvim_buf_get_lines(buf, lo - 1, hi, false)
        lines = {}
        for _, l in ipairs(raw) do
            lines[#lines + 1] = l:sub(c1, c2)
        end
    else
        if sl > el then
            sl, el = el, sl
            scol, ecol = ecol, scol
        end
        if sl == el then
            if scol > ecol then
                scol, ecol = ecol, scol
            end
            local l = vim.api.nvim_buf_get_lines(buf, sl - 1, sl, false)[1] or ""
            lines = { l:sub(scol, ecol) }
        else
            lines = vim.api.nvim_buf_get_lines(buf, sl - 1, el, false)
            lines[1] = lines[1]:sub(scol)
            lines[#lines] = lines[#lines]:sub(1, ecol)
        end
    end
    return lines
end

---The active visual selection, for the MCP `get_selection` tool.
---Pure function of the polled state (the bridge owns the anchor).
---@param mode string vim.fn.mode() value ('v' | 'V' | '\22' | ...)
---@param anchor integer[] {line, col0} captured at visual entry
---@param cursor integer[] {line, col0} live cursor
---@return { active: boolean, mode: string, path: string, start_line: integer, end_line: integer, text: string, truncated: boolean? }
function M.get_selection(mode, anchor, cursor)
    local buf = vim.api.nvim_get_current_buf()

    local sl, scol = anchor[1], anchor[2] + 1
    local el
    local ecol
    if mode == "V" then
        el, ecol = cursor[1], 0
    elseif mode == "\22" then
        -- blockwise: cursor char included
        el, ecol = cursor[1], cursor[2] + 1
    else
        -- charwise: cursor char included → 1-based inclusive end col
        el, ecol = cursor[1], cursor[2] + 1
    end

    local lines = M._extract(buf, sl, scol, el, ecol, mode)
    local text, truncated = M._truncate(table.concat(lines, "\n"), 200, 8000)
    return {
        active = true,
        mode = mode == "V" and "linewise" or (mode == "\22" and "blockwise" or "charwise"),
        path = M.current_buffer().path,
        start_line = math.min(sl, el),
        end_line = math.max(sl, el),
        text = text,
        truncated = truncated,
    }
end

return M
