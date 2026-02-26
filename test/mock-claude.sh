#!/bin/sh
# Mock claude CLI for testing install.sh
# Uses STATE_DIR env var to track marketplace/plugin state.

STATE_DIR="${STATE_DIR:-/tmp/mock-claude-state}"
mkdir -p "$STATE_DIR"

MARKETPLACE_FILE="$STATE_DIR/marketplace"
PLUGIN_FILE="$STATE_DIR/plugin"
PLUGIN_VERSION_FILE="$STATE_DIR/plugin_version"

case "$*" in
  "plugin marketplace list --json")
    if [ -f "$MARKETPLACE_FILE" ]; then
      cat <<EOF
[{"name": "exasol-skills", "source": "exasol-labs/exasol-agent-skills"}]
EOF
    else
      echo "[]"
    fi
    ;;

  "plugin marketplace add "*)
    touch "$MARKETPLACE_FILE"
    echo "Marketplace added."
    ;;

  "plugin marketplace update "*)
    if [ -f "$MARKETPLACE_FILE" ]; then
      echo "Marketplace updated."
    else
      echo "Marketplace not found." >&2
      exit 1
    fi
    ;;

  "plugin list --json")
    if [ -f "$PLUGIN_FILE" ]; then
      version="$(cat "$PLUGIN_VERSION_FILE" 2>/dev/null || echo "0.5.0")"
      cat <<EOF
[{"name": "exasol@exasol-skills", "version": "$version"}]
EOF
    else
      echo "[]"
    fi
    ;;

  "plugin install "*)
    touch "$PLUGIN_FILE"
    echo "0.5.0" > "$PLUGIN_VERSION_FILE"
    echo "Plugin installed."
    ;;

  "plugin update "*)
    if [ -f "$PLUGIN_FILE" ]; then
      echo "0.5.0" > "$PLUGIN_VERSION_FILE"
      echo "Plugin updated."
    else
      echo "Plugin not found." >&2
      exit 1
    fi
    ;;

  *)
    echo "Unknown command: $*" >&2
    exit 1
    ;;
esac
