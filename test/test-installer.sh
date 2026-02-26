#!/bin/sh
set -e

SCENARIO="${SCENARIO:-fresh}"
STATE_DIR="/tmp/mock-claude-state"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

pass() { printf '\033[0;32mPASS\033[0m %s\n' "$1"; }
fail() { printf '\033[0;31mFAIL\033[0m %s\n' "$1" >&2; exit 1; }

# Clean state
rm -rf "$STATE_DIR"
mkdir -p "$STATE_DIR"

# Prepend mock claude to PATH
export PATH="$SCRIPT_DIR:$PATH"
export STATE_DIR

# Create a "claude" wrapper that calls mock-claude.sh
cat > "$SCRIPT_DIR/claude" <<'WRAPPER'
#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec sh "$SCRIPT_DIR/mock-claude.sh" "$@"
WRAPPER
chmod +x "$SCRIPT_DIR/claude"

# Set up scenario
case "$SCENARIO" in
  fresh)
    echo "=== Scenario: fresh install ==="
    ;;
  idempotent)
    echo "=== Scenario: idempotent re-run ==="
    touch "$STATE_DIR/marketplace"
    touch "$STATE_DIR/plugin"
    echo "0.5.0" > "$STATE_DIR/plugin_version"
    ;;
  update)
    echo "=== Scenario: update from older version ==="
    touch "$STATE_DIR/marketplace"
    touch "$STATE_DIR/plugin"
    echo "0.3.0" > "$STATE_DIR/plugin_version"
    ;;
  *)
    fail "Unknown scenario: $SCENARIO"
    ;;
esac

# Run installer
output="$(sh "$REPO_DIR/install.sh" 2>&1)" || fail "install.sh exited with error"
echo "$output"

# Assertions
case "$SCENARIO" in
  fresh)
    [ -f "$STATE_DIR/marketplace" ] || fail "Marketplace was not added"
    [ -f "$STATE_DIR/plugin" ] || fail "Plugin was not installed"
    echo "$output" | grep -q "Adding marketplace" || fail "Expected 'Adding marketplace' in output"
    echo "$output" | grep -q "Installing plugin" || fail "Expected 'Installing plugin' in output"
    pass "Fresh install succeeded"
    ;;
  idempotent)
    echo "$output" | grep -q "Updating" || fail "Expected 'Updating' in output"
    echo "$output" | grep -q "v0.5.0" || fail "Expected version 0.5.0 in output"
    pass "Idempotent re-run succeeded"
    ;;
  update)
    version="$(cat "$STATE_DIR/plugin_version")"
    [ "$version" = "0.5.0" ] || fail "Expected version 0.5.0 after update, got $version"
    echo "$output" | grep -q "v0.5.0" || fail "Expected version 0.5.0 in output"
    pass "Update from older version succeeded"
    ;;
esac

# Cleanup wrapper
rm -f "$SCRIPT_DIR/claude"
