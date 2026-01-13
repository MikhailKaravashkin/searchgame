#!/usr/bin/env bash
set -euo pipefail

# Runs the MCP server with OPENAI_API_KEY loaded from macOS Keychain.
# This avoids storing the API key in files like .cursor/mcp.json.

SERVICE_NAME="searchgame-openai"
ACCOUNT_NAME="OPENAI_API_KEY"

if ! command -v security >/dev/null 2>&1; then
  echo "macOS 'security' tool not found. Are you on macOS?" >&2
  exit 1
fi

OPENAI_API_KEY="$(security find-generic-password -s "${SERVICE_NAME}" -a "${ACCOUNT_NAME}" -w 2>/dev/null || true)"

if [[ -z "${OPENAI_API_KEY}" ]]; then
  echo "OPENAI_API_KEY not found in Keychain." >&2
  echo "Run: scripts/store_openai_key_in_keychain.sh" >&2
  exit 1
fi

export OPENAI_API_KEY

# Optional overrides
export OPENAI_IMAGE_MODEL="${OPENAI_IMAGE_MODEL:-gpt-image-1}"
export OPENAI_IMAGE_SIZE="${OPENAI_IMAGE_SIZE:-1792x1024}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}/mcp/asset_server"

# Ensure deps are installed (non-interactive)
if [[ ! -d node_modules ]]; then
  npm install --silent
fi

node index.js
