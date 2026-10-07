-- nvim-mcp: Neovim side of the MCP server exposing nvim to AI agents (opencode).
--
-- The agent-facing server is server.py (Python, stdio), spawned on demand by
-- the agent daemon (see opencode.jsonc.snippet). This plugin is its home in
-- the INTERACTIVE instance; the RPC bridge (pynvim) + in-buffer diff UI land
-- in task2. Until then this module is intentionally empty.
local M = {}

function M.setup() end

return M
