#!/bin/sh
# Mock npx CLI for testing install.sh
# Records Codex add/list calls and simulates interactive selection,
# non-interactive installation, and router-verification failures.

STATE_DIR="${STATE_DIR:-/tmp/mock-claude-state}"
mkdir -p "$STATE_DIR"

case "$*" in
  "--yes skills@1.5.22 add exasol-labs/exasol-agent-skills --agent codex --skill * --global --yes")
    printf '%s\n' "$*" > "$STATE_DIR/codex_add_args"
    if [ "${MOCK_NPX_SKIP_INSTALL:-no}" = "yes" ]; then
      echo "No skills selected."
    else
      touch "$STATE_DIR/codex_skills"
      echo "Skills installed."
    fi
    ;;
  "--yes skills@1.5.22 add exasol-labs/exasol-agent-skills --agent codex --global")
    printf '%s\n' "$*" > "$STATE_DIR/codex_add_args"
    echo "Select skills:"
    if IFS= read -r selection && [ "$selection" = "exasol" ]; then
      touch "$STATE_DIR/codex_skills"
      echo "Selected skills installed."
    else
      echo "No skills selected."
    fi
    ;;
  "--yes skills@1.5.22 list --global --agent codex --json")
    printf '%s\n' "$*" > "$STATE_DIR/codex_list_args"
    if [ -f "$STATE_DIR/codex_skills" ]; then
      echo '[{"name":"exasol","scope":"global","agents":["Codex"]}]'
    else
      echo '[]'
    fi
    ;;
  *)
    echo "mock-npx: unknown args: $*" >&2
    exit 1
    ;;
esac
