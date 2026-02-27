#!/bin/sh
# Mock npx CLI for testing install.sh
# Simulates `npx skills add <repo> --agent codex` by touching a state file.

STATE_DIR="${STATE_DIR:-/tmp/mock-claude-state}"
mkdir -p "$STATE_DIR"

case "$*" in
  "skills add "*)
    touch "$STATE_DIR/codex_skills"
    echo "Skills installed."
    ;;
  *)
    echo "mock-npx: unknown args: $*" >&2
    exit 1
    ;;
esac
