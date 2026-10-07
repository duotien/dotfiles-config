return {
    -- Local plugin (not git): the nvim-mcp interactive side, living in the
    -- repo at local/nvim-mcp. `dir` puts its `lua/` on the runtimepath so
    -- the Python MCP server's RPC call `require('nvim_mcp')` (task2) resolves.
    -- Passive: loads nothing active until the MCP server connects.
    {
        "nvim-mcp",
        dir = vim.fn.stdpath("config") .. "/local/nvim-mcp",
    },
}
