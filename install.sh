#!/bin/sh
set -e

MARKETPLACE_NAME="exasol-skills"
MARKETPLACE_REPO="exasol-labs/exasol-agent-skills"
PLUGIN_ID="exasol@${MARKETPLACE_NAME}"
PLUGIN_NAME="exasol"

info()  { printf '\033[0;34m[info]\033[0m  %s\n' "$1"; }
ok()    { printf '\033[0;32m[ok]\033[0m    %s\n' "$1"; }
warn()  { printf '\033[0;33m[warn]\033[0m  %s\n' "$1"; }
fail()  { printf '\033[0;31m[error]\033[0m %s\n' "$1" >&2; exit 1; }

command -v claude >/dev/null 2>&1 || fail "claude CLI not found. Install: https://docs.anthropic.com/en/docs/claude-code/overview"

# --- marketplace ---
info "Checking marketplace..."
if claude plugin marketplace list --json 2>/dev/null | grep -q "\"${MARKETPLACE_NAME}\""; then
  info "Marketplace '${MARKETPLACE_NAME}' found. Updating..."
  claude plugin marketplace update "${MARKETPLACE_NAME}" 2>/dev/null || true
else
  info "Adding marketplace '${MARKETPLACE_NAME}'..."
  claude plugin marketplace add "${MARKETPLACE_REPO}"
fi

# --- plugin ---
info "Checking plugin..."
if claude plugin list --json 2>/dev/null | grep -q "\"${PLUGIN_ID}\""; then
  info "Plugin '${PLUGIN_ID}' found. Updating..."
  claude plugin update "${PLUGIN_NAME}" --scope user 2>/dev/null || true
else
  info "Installing plugin '${PLUGIN_ID}'..."
  claude plugin install "${PLUGIN_ID}" --scope user
fi

# --- verify ---
info "Verifying..."
installed_version="$(claude plugin list --json 2>/dev/null | grep -A5 "\"${PLUGIN_ID}\"" | grep '"version"' | head -1 | sed 's/.*"version"[^"]*"\([^"]*\)".*/\1/')"

if [ -n "$installed_version" ]; then
  ok "Exasol plugin v${installed_version} installed. Start a new Claude Code session to use it."
else
  warn "Could not verify version, but installation may have succeeded."
  ok "Run 'claude plugin list' to check. Start a new Claude Code session to use it."
fi
