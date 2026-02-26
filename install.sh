#!/bin/sh
set -e

MARKETPLACE_NAME="exasol-skills"
MARKETPLACE_REPO="exasol-labs/exasol-agent-skills"
MARKETPLACE_JSON_URL="https://raw.githubusercontent.com/${MARKETPLACE_REPO}/main/.claude-plugin/marketplace.json"
PLUGIN_ID="exasol@${MARKETPLACE_NAME}"
PLUGIN_NAME="exasol"
EXAPUMP_REPO="exasol-labs/exapump"
EXAPUMP_INSTALL_URL="https://raw.githubusercontent.com/${EXAPUMP_REPO}/main/install.sh"
EXAPUMP_LATEST_API="https://api.github.com/repos/${EXAPUMP_REPO}/releases/latest"

info()  { printf '\033[0;34m[info]\033[0m  %s\n' "$1"; }
ok()    { printf '\033[0;32m[ok]\033[0m    %s\n' "$1"; }
warn()  { printf '\033[0;33m[warn]\033[0m  %s\n' "$1"; }
fail()  { printf '\033[0;31m[error]\033[0m %s\n' "$1" >&2; exit 1; }

ask() {
  printf '\033[0;33m[prompt]\033[0m %s [Y/n] ' "$1"
  if [ -t 0 ]; then
    read -r answer
    case "$answer" in
      [Nn]*) return 1 ;;
      *) return 0 ;;
    esac
  else
    # Non-interactive (piped) — default to yes
    printf 'Y (non-interactive)\n'
    return 0
  fi
}

# --- exapump ---
info "Checking exapump..."
latest_version=""
if command -v curl >/dev/null 2>&1; then
  latest_version="$(curl -fsSL "$EXAPUMP_LATEST_API" 2>/dev/null | sed -n 's/.*"tag_name"[^"]*"\([^"]*\)".*/\1/p')"
fi

if command -v exapump >/dev/null 2>&1; then
  current_version="$(exapump --version 2>/dev/null | sed -n 's/.*[[:space:]]\{1,\}\(v\{0,1\}[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')"
  # Normalize: strip leading 'v' for comparison
  current_num="${current_version#v}"
  latest_num="${latest_version#v}"

  if [ -n "$latest_num" ] && [ "$current_num" != "$latest_num" ]; then
    info "exapump ${current_version} installed, latest is ${latest_version}."
    if ask "Update exapump to ${latest_version}?"; then
      info "Updating exapump..."
      curl -fsSL "$EXAPUMP_INSTALL_URL" | sh
      ok "exapump updated to ${latest_version}."
    else
      info "Skipping exapump update."
    fi
  else
    ok "exapump ${current_version} is up to date."
  fi
else
  warn "exapump not found."
  if [ -n "$latest_version" ]; then
    if ask "Install exapump ${latest_version}?"; then
      info "Installing exapump..."
      curl -fsSL "$EXAPUMP_INSTALL_URL" | sh
      ok "exapump installed."
    else
      info "Skipping exapump install. You can install later: https://github.com/${EXAPUMP_REPO}"
    fi
  else
    warn "Could not determine latest exapump version. Install manually: https://github.com/${EXAPUMP_REPO}"
  fi
fi

# --- claude CLI ---
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
VERSION="$(curl -fsSL "$MARKETPLACE_JSON_URL" 2>/dev/null | sed -n 's/.*"version"[^"]*"\([^"]*\)".*/\1/p' | head -1)"
if claude plugin list --json 2>/dev/null | grep -q "\"${PLUGIN_ID}\""; then
  ok "Exasol plugin v${VERSION:-unknown} installed. Start a new Claude Code session to use it."
else
  warn "Could not verify installation."
  ok "Run 'claude plugin list' to check. Start a new Claude Code session to use it."
fi
