#!/bin/sh
set -e

SCENARIO="${SCENARIO:-fresh}"
STATE_DIR="/tmp/mock-claude-state"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MOCK_BIN="$STATE_DIR/bin"

pass() { printf '\033[0;32mPASS\033[0m %s\n' "$1"; }
fail() { printf '\033[0;31mFAIL\033[0m %s\n' "$1" >&2; exit 1; }

# Clean state
rm -rf "$STATE_DIR"
mkdir -p "$STATE_DIR" "$MOCK_BIN"

# Create mock wrappers in a state-local bin dir (avoids leftover files in test/)
cat > "$MOCK_BIN/claude" <<WRAPPER
#!/bin/sh
exec sh "$SCRIPT_DIR/mock-claude.sh" "\$@"
WRAPPER

cat > "$MOCK_BIN/curl" <<WRAPPER
#!/bin/sh
exec sh "$SCRIPT_DIR/mock-curl.sh" "\$@"
WRAPPER

cat > "$MOCK_BIN/exapump" <<WRAPPER
#!/bin/sh
exec sh "$SCRIPT_DIR/mock-exapump.sh" "\$@"
WRAPPER

chmod +x "$MOCK_BIN/claude" "$MOCK_BIN/curl" "$MOCK_BIN/exapump"

export STATE_DIR
export MOCK_EXAPUMP_LATEST="${MOCK_EXAPUMP_LATEST:-v0.6.0}"

# Build a sanitized PATH: mock bin + only system dirs (exclude user-local paths with real exapump)
SYS_PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="$MOCK_BIN:$SYS_PATH"

# Set up scenario
case "$SCENARIO" in
  fresh)
    echo "=== Scenario: fresh install (no exapump, no plugin) ==="
    # Remove exapump mock so command -v fails
    rm -f "$MOCK_BIN/exapump"
    ;;
  idempotent)
    echo "=== Scenario: idempotent re-run ==="
    touch "$STATE_DIR/marketplace"
    touch "$STATE_DIR/plugin"
    echo "0.5.0" > "$STATE_DIR/plugin_version"
    echo "v0.6.0" > "$STATE_DIR/exapump_version"
    ;;
  update)
    echo "=== Scenario: update from older version ==="
    touch "$STATE_DIR/marketplace"
    touch "$STATE_DIR/plugin"
    echo "0.3.0" > "$STATE_DIR/plugin_version"
    echo "v0.4.0" > "$STATE_DIR/exapump_version"
    ;;
  *)
    fail "Unknown scenario: $SCENARIO"
    ;;
esac

# Run installer (non-interactive — ask() defaults to Y)
output="$(echo "" | sh "$REPO_DIR/install.sh" 2>&1)" || fail "install.sh exited with error"
echo "$output"

# Assertions
case "$SCENARIO" in
  fresh)
    [ -f "$STATE_DIR/marketplace" ] || fail "Marketplace was not added"
    [ -f "$STATE_DIR/plugin" ] || fail "Plugin was not installed"
    echo "$output" | grep -q "Adding marketplace" || fail "Expected 'Adding marketplace' in output"
    echo "$output" | grep -q "Installing plugin" || fail "Expected 'Installing plugin' in output"
    echo "$output" | grep -q "exapump not found" || fail "Expected exapump not-found warning"
    echo "$output" | grep -q "Install exapump" || fail "Expected exapump install prompt"
    pass "Fresh install succeeded"
    ;;
  idempotent)
    echo "$output" | grep -q "Updating" || fail "Expected 'Updating' in output"
    echo "$output" | grep -q "v0.6.0" || fail "Expected marketplace version 0.6.0 in output"
    echo "$output" | grep -q "up to date" || fail "Expected exapump up-to-date message"
    pass "Idempotent re-run succeeded"
    ;;
  update)
    version="$(cat "$STATE_DIR/plugin_version")"
    [ "$version" = "0.5.0" ] || fail "Expected plugin version 0.5.0 after update, got $version"
    echo "$output" | grep -q "v0.6.0" || fail "Expected marketplace version 0.6.0 in output"
    echo "$output" | grep -q "Update exapump" || fail "Expected exapump update prompt"
    pass "Update from older version succeeded"
    ;;
esac
