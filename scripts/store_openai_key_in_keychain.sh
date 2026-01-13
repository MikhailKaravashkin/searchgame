#!/usr/bin/env bash
set -euo pipefail

# Stores OPENAI_API_KEY in macOS Keychain under:
# service: searchgame-openai
# account: OPENAI_API_KEY

SERVICE_NAME="searchgame-openai"
ACCOUNT_NAME="OPENAI_API_KEY"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "Set OPENAI_API_KEY in your shell first, e.g.:" >&2
  echo "  export OPENAI_API_KEY=..." >&2
  exit 1
fi

# -U updates existing item
security add-generic-password -U -s "${SERVICE_NAME}" -a "${ACCOUNT_NAME}" -w "${OPENAI_API_KEY}"

echo "Saved OPENAI_API_KEY to Keychain (service=${SERVICE_NAME}, account=${ACCOUNT_NAME})."
