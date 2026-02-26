#!/bin/sh
# Mock exapump CLI for testing install.sh
# Reads version from STATE_DIR/exapump_version

STATE_DIR="${STATE_DIR:-/tmp/mock-claude-state}"

case "$*" in
  --version|-V)
    if [ -f "$STATE_DIR/exapump_version" ]; then
      version="$(cat "$STATE_DIR/exapump_version")"
      echo "exapump ${version}"
    else
      echo "exapump not found" >&2
      exit 1
    fi
    ;;
  *)
    echo "mock-exapump: unknown args: $*" >&2
    exit 1
    ;;
esac
