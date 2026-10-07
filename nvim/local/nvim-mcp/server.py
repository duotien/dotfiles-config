"""nvim-mcp: MCP server (stdio) exposing Neovim tools to AI agents.

Opencode spawns this process and speaks JSON-RPC over stdin/stdout.
Each tool is a plain Python function in tools/ — registering a new
tool is: write the function, import it, mcp.tool()(it).
"""

from mcp.server import MCPServer

from tools.ping import ping
from tools.propose_edit import propose_edit

mcp = MCPServer("nvim-mcp")
mcp.tool()(ping)
mcp.tool()(propose_edit)

if __name__ == "__main__":
    mcp.run()  # stdio transport
