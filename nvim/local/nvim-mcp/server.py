"""nvim-mcp: MCP server (stdio) exposing Neovim tools to AI agents.

Opencode spawns this process and speaks JSON-RPC over stdin/stdout.
Each tool is a plain Python function in tools/ — registering a new
tool is: write the function, import it, mcp.tool()(it).
"""

from mcp.server import MCPServer

import nvim_bridge
from tools.current_buffer import current_buffer
from tools.get_selection import get_selection
from tools.ping import ping
from tools.propose_edit import propose_edit

mcp = MCPServer("nvim-mcp")
mcp.tool()(ping)
mcp.tool()(current_buffer)
mcp.tool()(get_selection)
mcp.tool()(propose_edit)

# get_selection needs the visual anchor (cursor at visual entry); this build
# exposes no VisualMode event, so the bridge polls it in a daemon thread.
nvim_bridge.start_poller()

if __name__ == "__main__":
    mcp.run()  # stdio transport
