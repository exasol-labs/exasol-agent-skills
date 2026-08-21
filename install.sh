#!/bin/sh
set -e

umask 077
TEMP_FILE=""
cleanup() {
  if [ -n "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
  fi
}
trap cleanup EXIT HUP INT TERM

MARKETPLACE_NAME="exasol-skills"
MARKETPLACE_REPO="exasol-labs/exasol-agent-skills"
MARKETPLACE_JSON_URL="https://raw.githubusercontent.com/${MARKETPLACE_REPO}/main/.claude-plugin/marketplace.json"
PLUGIN_ID="exasol@${MARKETPLACE_NAME}"
EXAPUMP_REPO="exasol-labs/exapump"
EXAPUMP_INSTALL_BASE="https://raw.githubusercontent.com/${EXAPUMP_REPO}"
EXAPUMP_LATEST_API="https://api.github.com/repos/${EXAPUMP_REPO}/releases/latest"
CODEX_SKILLS_CLI="skills@1.5.22"

info()  { printf '\033[0;34m[info]\033[0m  %s\n' "$1"; }
ok()    { printf '\033[0;32m[ok]\033[0m    %s\n' "$1"; }
warn()  { printf '\033[0;33m[warn]\033[0m  %s\n' "$1"; }
fail()  { printf '\033[0;31m[error]\033[0m %s\n' "$1" >&2; exit 1; }

has_terminal() {
  if [ -t 0 ]; then
    return 0
  fi
  if (: </dev/tty) 2>/dev/null; then
    return 0
  fi
  return 1
}

download_and_run() {
  url="$1"
  version="$2"
  TEMP_FILE="$(mktemp "${TMPDIR:-/tmp}/exasol-agent-skills.XXXXXX")" || fail "Could not create a secure temporary file."
  curl -fsSL --proto '=https' --tlsv1.2 "$url" -o "$TEMP_FILE" || fail "Could not download the installer from $url."
  EXAPUMP_VERSION="$version" sh "$TEMP_FILE"
}

manage_exapump() {
  prompt="$1"
  case "${INSTALL_EXAPUMP:-}" in
    1|true|yes) return 0 ;;
    0|false|no) return 1 ;;
    "")
      if has_terminal; then
        ask "$prompt"
        return $?
      fi
      info "Skipping optional exapump installation in non-interactive mode. Set INSTALL_EXAPUMP=yes to enable it."
      return 1
      ;;
    *) fail "Unknown INSTALL_EXAPUMP value '$INSTALL_EXAPUMP'. Use 'yes', 'true', '1', 'no', 'false', or '0'." ;;
  esac
}

ask() {
  if has_terminal; then
    if [ -t 1 ]; then
      printf '\033[0;33m[prompt]\033[0m %s [Y/n] ' "$1"
    else
      printf '\033[0;33m[prompt]\033[0m %s [Y/n] ' "$1" >/dev/tty
    fi
    if [ -t 0 ]; then
      read -r answer
    else
      read -r answer </dev/tty
    fi
    case "$answer" in
      [Nn]*) return 1 ;;
      *) return 0 ;;
    esac
  else
    # Callers that deliberately allow a non-interactive default receive yes.
    printf '\033[0;33m[prompt]\033[0m %s [Y/n] ' "$1"
    printf 'Y (non-interactive)\n'
    return 0
  fi
}

terminal_info() {
  if [ -t 1 ]; then
    info "$1"
  else
    info "$1" >/dev/tty
  fi
}

run_on_terminal() {
  if [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; then
    "$@"
  else
    "$@" </dev/tty >/dev/tty 2>&1
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
  elif has_terminal; then
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
command -v curl >/dev/null 2>&1 || fail "curl is required to check releases and download installers."
latest_version=""
latest_release=""
if latest_release="$(curl -fsSL --proto '=https' --tlsv1.2 "$EXAPUMP_LATEST_API" 2>/dev/null)"; then
  latest_version="$(printf '%s\n' "$latest_release" | sed -n 's/.*"tag_name"[^"]*"\(v\{0,1\}[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)".*/\1/p')"
fi

if command -v exapump >/dev/null 2>&1; then
  current_version="$(exapump --version 2>/dev/null | sed -n 's/.*[[:space:]]\{1,\}\(v\{0,1\}[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')"
  # Normalize: strip leading 'v' for comparison
  current_num="${current_version#v}"
  latest_num="${latest_version#v}"

  if [ -z "$current_num" ]; then
    warn "exapump was found, but its version could not be determined. Leaving it unchanged."
  elif [ -z "$latest_num" ]; then
    warn "Could not determine the latest exapump version. Leaving ${current_version} unchanged."
  elif [ "$current_num" != "$latest_num" ]; then
    info "exapump ${current_version} installed, latest is ${latest_version}."
    if manage_exapump "Update exapump to ${latest_version}?"; then
      info "Updating exapump..."
      download_and_run "${EXAPUMP_INSTALL_BASE}/${latest_version}/install.sh" "$latest_num"
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
    if manage_exapump "Install exapump ${latest_version}?"; then
      info "Installing exapump..."
      download_and_run "${EXAPUMP_INSTALL_BASE}/${latest_version}/install.sh" "${latest_version#v}"
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
    claude plugin marketplace update "${MARKETPLACE_NAME}"
  else
    info "Adding marketplace '${MARKETPLACE_NAME}'..."
    claude plugin marketplace add "${MARKETPLACE_REPO}"
  fi

  # --- plugin ---
  info "Checking plugin..."
  if claude plugin list --json 2>/dev/null | grep -q "\"${PLUGIN_ID}\""; then
    info "Plugin '${PLUGIN_ID}' found. Updating..."
    claude plugin update "${PLUGIN_ID}" --scope user
  else
    info "Installing plugin '${PLUGIN_ID}'..."
    claude plugin install "${PLUGIN_ID}" --scope user
  fi
fi

# --- OpenAI Codex ---
if [ "$INSTALL_CODEX" -eq 1 ]; then
  case "${CODEX_SKILLS:-auto}" in
    auto)
      if has_terminal; then CODEX_INSTALL_MODE="prompt"; else CODEX_INSTALL_MODE="all"; fi
      ;;
    prompt)
      has_terminal || fail "CODEX_SKILLS=prompt requires an interactive terminal."
      CODEX_INSTALL_MODE="prompt"
      ;;
    all) CODEX_INSTALL_MODE="all" ;;
    *) fail "Unknown CODEX_SKILLS value '$CODEX_SKILLS'. Use 'auto', 'prompt', or 'all'." ;;
  esac

  if [ "$CODEX_INSTALL_MODE" = "prompt" ]; then
    terminal_info "Select Exasol skills for OpenAI Codex. Include 'exasol' for shared routing."
    run_on_terminal npx --yes "$CODEX_SKILLS_CLI" add \
      "exasol-labs/exasol-agent-skills" --agent codex --global
  else
    info "Non-interactive mode: installing all Exasol skills globally for OpenAI Codex..."
    npx --yes "$CODEX_SKILLS_CLI" add "exasol-labs/exasol-agent-skills" \
      --agent codex --skill '*' --global --yes
  fi

  CODEX_SKILLS_JSON="$(npx --yes "$CODEX_SKILLS_CLI" list --global --agent codex --json)"
  if printf '%s\n' "$CODEX_SKILLS_JSON" | grep -q '"name"[[:space:]]*:[[:space:]]*"exasol"'; then
    if [ "$CODEX_INSTALL_MODE" = "prompt" ]; then
      ok "Selected Exasol skills installed for OpenAI Codex; shared router verified."
    else
      ok "All Exasol skills installed for OpenAI Codex; shared router verified."
    fi
  else
    fail "Codex installation completed without the shared 'exasol' router. Select 'exasol' together with any specialized skills."
  fi
fi

# --- verify ---
info "Verifying..."
VERSION="$(curl -fsSL --proto '=https' --tlsv1.2 "$MARKETPLACE_JSON_URL" 2>/dev/null | sed -n 's/.*"version"[^"]*"\([^"]*\)".*/\1/p' | head -1)"

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
