#!/usr/bin/env bash
# Install the nvim-mcp opencode skill as a symlink into the global skills
# directory, keeping this repo the single source of truth.
#   Global skills dir: ~/.config/opencode/skills (opencode discovers it
#   automatically; see https://opencode.ai/v2/docs/skills).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${OPENCODE_CONFIG:-$HOME/.config/opencode}/skills"
mkdir -p "$SKILLS_DIR"
ln -sfn "$HERE/skills/nvim-mcp" "$SKILLS_DIR/nvim-mcp"
echo "installed: $SKILLS_DIR/nvim-mcp -> $HERE/skills/nvim-mcp"
echo "restart the opencode service (opencode service restart) to pick it up"
