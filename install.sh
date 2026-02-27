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

choose_agents() {
  if [ -n "$AGENT" ]; then
    case "$AGENT" in
      claude) INSTALL_CLAUDE=1; INSTALL_CODEX=0 ;;
      codex)  INSTALL_CLAUDE=0; INSTALL_CODEX=1 ;;
      both)   INSTALL_CLAUDE=1; INSTALL_CODEX=1 ;;
      *)      fail "Unknown AGENT value '$AGENT'. Use 'claude', 'codex', or 'both'." ;;
    esac
  elif [ -t 0 ]; then
    INSTALL_CLAUDE=0
    INSTALL_CODEX=0
    if ask "Install for Claude Code?"; then INSTALL_CLAUDE=1; fi
    if ask "Install for OpenAI Codex?"; then INSTALL_CODEX=1; fi
    [ "$INSTALL_CLAUDE" -eq 1 ] || [ "$INSTALL_CODEX" -eq 1 ] || fail "No agent selected."
  else
    info "Non-interactive mode: installing for both agents. Set AGENT=claude or AGENT=codex to select one."
    INSTALL_CLAUDE=1
    INSTALL_CODEX=1
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

# --- agent selection ---
choose_agents

# --- prerequisite checks ---
if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  command -v claude >/dev/null 2>&1 || fail "claude CLI not found. Install: https://docs.anthropic.com/en/docs/claude-code/overview"
fi
if [ "$INSTALL_CODEX" -eq 1 ]; then
  command -v npx >/dev/null 2>&1 || fail "npx not found. Install Node.js: https://nodejs.org"
fi

# --- Claude Code ---
if [ "$INSTALL_CLAUDE" -eq 1 ]; then
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
fi

# --- OpenAI Codex ---
if [ "$INSTALL_CODEX" -eq 1 ]; then
  info "Installing Exasol skills for OpenAI Codex..."
  npx skills add "exasol-labs/exasol-agent-skills" --agent codex
  ok "Exasol skills installed for OpenAI Codex."
fi

# --- verify ---
info "Verifying..."
VERSION="$(curl -fsSL "$MARKETPLACE_JSON_URL" 2>/dev/null | sed -n 's/.*"version"[^"]*"\([^"]*\)".*/\1/p' | head -1)"

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  if claude plugin list --json 2>/dev/null | grep -q "\"${PLUGIN_ID}\""; then
    ok "Exasol plugin v${VERSION:-unknown} installed for Claude Code. Start a new session to use it."
  else
    warn "Could not verify Claude Code installation."
    ok "Run 'claude plugin list' to check. Start a new Claude Code session to use it."
  fi
fi

if [ "$INSTALL_CODEX" -eq 1 ]; then
  ok "Exasol skills v${VERSION:-unknown} installed for OpenAI Codex."
fi
