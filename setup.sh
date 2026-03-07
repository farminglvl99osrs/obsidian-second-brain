#!/usr/bin/env bash
set -euo pipefail

# Obsidian Second Brain — Setup Script
# Configures Claude Code MCP integration for this vault.
#
# Usage:
#   ./setup.sh                    # interactive setup
#   ./setup.sh --vault-path .     # specify vault path explicitly

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}Obsidian Second Brain — Setup${NC}"
echo ""

# ── Step 1: Check prerequisites ──────────────────────────────────────────────

echo -e "${BOLD}[1/5] Checking prerequisites...${NC}"

if ! command -v node &>/dev/null; then
    echo -e "${RED}Error: Node.js not found. Install it first (required for MCP server).${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"

if ! command -v npx &>/dev/null; then
    echo -e "${RED}Error: npx not found. Install Node.js 18+ to get npx.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} npx available"

if ! command -v claude &>/dev/null; then
    echo -e "${YELLOW}Warning: Claude Code CLI not found. MCP config will be written but can't verify.${NC}"
fi

# ── Step 2: Determine vault path ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}[2/5] Vault location${NC}"

VAULT_PATH="${1:-}"
if [ -z "$VAULT_PATH" ]; then
    VAULT_PATH="$(cd "$(dirname "$0")" && pwd)"
fi

# Resolve to absolute path
VAULT_PATH="$(cd "$VAULT_PATH" && pwd)"
echo -e "  Vault path: ${GREEN}${VAULT_PATH}${NC}"

# ── Step 3: Get Obsidian API key ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}[3/5] Obsidian Local REST API${NC}"
echo ""
echo -e "  ${DIM}If you haven't already:${NC}"
echo -e "  ${DIM}1. Open Obsidian and open this folder as a vault${NC}"
echo -e "  ${DIM}2. Settings > Community plugins > Enable community plugins${NC}"
echo -e "  ${DIM}3. Browse > Install 'Local REST API' by Adam Coddington${NC}"
echo -e "  ${DIM}4. Enable the plugin and copy the API key from its settings${NC}"
echo ""
read -rp "  Paste your Obsidian API key: " API_KEY

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: API key cannot be empty.${NC}"
    exit 1
fi

# Verify API is reachable
echo -e "  Verifying API connection..."
if curl -sk -H "Authorization: Bearer ${API_KEY}" https://127.0.0.1:27124/ &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Obsidian REST API is reachable"
else
    echo -e "  ${YELLOW}Warning: Could not reach Obsidian REST API at https://127.0.0.1:27124/${NC}"
    echo -e "  ${YELLOW}Make sure Obsidian is open with the Local REST API plugin enabled.${NC}"
    echo -e "  ${YELLOW}Continuing anyway — you can verify later.${NC}"
fi

# ── Step 4: Configure Claude MCP ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}[4/5] Configuring Claude Code MCP server${NC}"

MCP_CONFIG="$HOME/.claude/mcp.json"
mkdir -p "$HOME/.claude"

if [ -f "$MCP_CONFIG" ]; then
    # Check if obsidian is already configured
    if python3 -c "import json; d=json.load(open('$MCP_CONFIG')); exit(0 if 'obsidian' in d.get('mcpServers',{}) else 1)" 2>/dev/null; then
        echo -e "  ${YELLOW}Obsidian MCP server already configured. Updating API key...${NC}"
        python3 -c "
import json
with open('$MCP_CONFIG') as f:
    config = json.load(f)
config['mcpServers']['obsidian']['env']['OBSIDIAN_API_KEY'] = '$API_KEY'
with open('$MCP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
"
    else
        echo -e "  Adding obsidian to existing MCP config..."
        python3 -c "
import json
with open('$MCP_CONFIG') as f:
    config = json.load(f)
config.setdefault('mcpServers', {})['obsidian'] = {
    'command': 'npx',
    'args': ['-y', 'mcp-obsidian'],
    'env': {
        'OBSIDIAN_API_KEY': '$API_KEY',
        'OBSIDIAN_HOST': '127.0.0.1',
        'OBSIDIAN_PORT': '27124'
    }
}
with open('$MCP_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
"
    fi
else
    echo -e "  Creating MCP config..."
    cat > "$MCP_CONFIG" <<MCPEOF
{
  "mcpServers": {
    "obsidian": {
      "command": "npx",
      "args": ["-y", "mcp-obsidian"],
      "env": {
        "OBSIDIAN_API_KEY": "${API_KEY}",
        "OBSIDIAN_HOST": "127.0.0.1",
        "OBSIDIAN_PORT": "27124"
      }
    }
  }
}
MCPEOF
fi
echo -e "  ${GREEN}✓${NC} MCP config written to ${MCP_CONFIG}"

# ── Step 5: Create session directory ─────────────────────────────────────────

echo ""
echo -e "${BOLD}[5/5] Setting up your session directory${NC}"

read -rp "  Your name (for session logs, e.g. 'dylan'): " USERNAME
USERNAME="${USERNAME:-user}"

mkdir -p "${VAULT_PATH}/sessions/${USERNAME}"
echo -e "  ${GREEN}✓${NC} Created sessions/${USERNAME}/"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo ""
echo -e "  1. Add these behavioral rules to your Claude auto-memory"
echo -e "     (${DIM}~/.claude/projects/<your-project>/memory/MEMORY.md${NC}):"
echo ""
echo -e "     ${DIM}## Obsidian Second Brain (Vault: ${VAULT_PATH})${NC}"
echo -e "     ${DIM}- **Start:** Run \`git pull\` in the vault, then use Obsidian \`search\` tool for context.${NC}"
echo -e "     ${DIM}- **During:** When discovering new relationships or decisions, use \`append_content\`${NC}"
echo -e "     ${DIM}  or \`patch_content\` to update notes. Always update \`last_updated\` frontmatter.${NC}"
echo -e "     ${DIM}- **End:** When I say \"wrap it up\", create a session summary in${NC}"
echo -e "     ${DIM}  \`sessions/${USERNAME}/YYYY-MM-DD-<topic>.md\`, then git add, commit, and push.${NC}"
echo ""
echo -e "  2. Restart Claude Code to load the MCP server"
echo ""
echo -e "  3. Start a session and say: ${DIM}\"Search Obsidian for context on <repo>\"${NC}"
echo ""
