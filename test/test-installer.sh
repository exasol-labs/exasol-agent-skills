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

cat > "$MOCK_BIN/npx" <<WRAPPER
#!/bin/sh
exec sh "$SCRIPT_DIR/mock-npx.sh" "\$@"
WRAPPER

chmod +x "$MOCK_BIN/claude" "$MOCK_BIN/curl" "$MOCK_BIN/exapump" "$MOCK_BIN/npx"

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
  fresh-exapump)
    echo "=== Scenario: fresh install with explicit exapump opt-in ==="
    rm -f "$MOCK_BIN/exapump"
    export INSTALL_EXAPUMP=yes
    ;;
  exapump-api-failure)
    echo "=== Scenario: exapump release lookup failure ==="
    rm -f "$MOCK_BIN/exapump"
    export MOCK_EXAPUMP_API_FAILURE=yes
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
    export INSTALL_EXAPUMP=yes
    ;;
  fresh-claude)
    echo "=== Scenario: fresh install (Claude Code only) ==="
    rm -f "$MOCK_BIN/exapump"
    rm -f "$MOCK_BIN/npx"
    export AGENT=claude
    ;;
  fresh-codex)
    echo "=== Scenario: fresh install (Codex only) ==="
    rm -f "$MOCK_BIN/exapump"
    rm -f "$MOCK_BIN/claude"
    export AGENT=codex
    ;;
  codex-verification-failure)
    echo "=== Scenario: Codex CLI succeeds without installing skills ==="
    rm -f "$MOCK_BIN/exapump"
    rm -f "$MOCK_BIN/claude"
    export AGENT=codex
    export MOCK_NPX_SKIP_INSTALL=yes
    ;;
  piped-interactive-codex)
    echo "=== Scenario: curl-piped interactive Codex skill selection ==="
    rm -f "$MOCK_BIN/exapump"
    ;;
  *)
    fail "Unknown scenario: $SCENARIO"
    ;;
esac

if [ "$SCENARIO" = "piped-interactive-codex" ]; then
  output_file="$STATE_DIR/piped-interactive-output"
  if ! printf 'exasol\n' \
    | script -qec "cat '$REPO_DIR/install.sh' | AGENT=codex CODEX_SKILLS=prompt INSTALL_EXAPUMP=no sh > '$output_file' 2>&1" /dev/null \
    >/dev/null 2>&1; then
    [ ! -f "$output_file" ] || cat "$output_file" >&2
    fail "curl-piped interactive install failed"
  fi
  output="$(cat "$output_file")"
  echo "$output"
  [ ! -f "$STATE_DIR/marketplace" ] || fail "Claude marketplace should not be added"
  [ -f "$STATE_DIR/codex_skills" ] || fail "Selected Codex skills were not installed"
  grep -Fq -- "--agent codex --global" "$STATE_DIR/codex_add_args" || fail "Codex picker was not interactive"
  if grep -Fq -- "--skill *" "$STATE_DIR/codex_add_args"; then fail "Interactive Codex install bypassed skill selection"; fi
  echo "$output" | grep -q "Select Exasol skills for OpenAI Codex" || fail "Expected interactive Codex selection message"
  echo "$output" | grep -q "shared router verified" || fail "Expected selected-skill verification"
  pass "Curl-piped interactive Codex selection with redirected output succeeded"
  exit 0
fi

# Run installer without a terminal (automation path).
if [ "$SCENARIO" = "codex-verification-failure" ]; then
  if output="$(echo "" | sh "$REPO_DIR/install.sh" 2>&1)"; then
    fail "install.sh reported success after Codex installed no skills"
  fi
  echo "$output"
  echo "$output" | grep -q "without the shared 'exasol' router" || fail "Expected Codex verification failure"
  [ ! -f "$STATE_DIR/codex_skills" ] || fail "Codex skills should not exist in verification-failure scenario"
  pass "Codex no-selection result was rejected"
  exit 0
fi

output="$(echo "" | sh "$REPO_DIR/install.sh" 2>&1)" || fail "install.sh exited with error"
echo "$output"

assert_codex_install() {
  [ -f "$STATE_DIR/codex_skills" ] || fail "Codex skills were not installed"
  grep -Fq -- "--skill * --global --yes" "$STATE_DIR/codex_add_args" || fail "Codex install did not select all skills non-interactively at global scope"
  grep -Fq -- "list --global --agent codex --json" "$STATE_DIR/codex_list_args" || fail "Codex installation was not verified"
  echo "$output" | grep -q "shared router verified" || fail "Expected Codex shared-router verification message"
}

# Assertions
case "$SCENARIO" in
  fresh)
    [ -f "$STATE_DIR/marketplace" ] || fail "Marketplace was not added"
    [ -f "$STATE_DIR/plugin" ] || fail "Plugin was not installed"
    assert_codex_install
    echo "$output" | grep -q "Adding marketplace" || fail "Expected 'Adding marketplace' in output"
    echo "$output" | grep -q "Installing plugin" || fail "Expected 'Installing plugin' in output"
    echo "$output" | grep -q "exapump not found" || fail "Expected exapump not-found warning"
    echo "$output" | grep -q "Skipping optional exapump" || fail "Expected non-interactive exapump skip message"
    [ ! -f "$STATE_DIR/exapump_version" ] || fail "exapump should not be installed without explicit opt-in"
    echo "$output" | grep -q "installing all Exasol skills globally for OpenAI Codex" || fail "Expected Codex install message"
    pass "Fresh install succeeded"
    ;;
  fresh-exapump)
    assert_codex_install
    [ -f "$STATE_DIR/exapump_version" ] || fail "exapump was not installed after explicit opt-in"
    grep -q '/v0.6.0/install.sh$' "$STATE_DIR/exapump_install_url" || fail "Expected a release-tag-pinned exapump installer URL"
    echo "$output" | grep -q "exapump installed" || fail "Expected exapump installed message"
    pass "Explicit exapump install succeeded"
    ;;
  exapump-api-failure)
    [ -f "$STATE_DIR/marketplace" ] || fail "Marketplace was not added"
    [ -f "$STATE_DIR/plugin" ] || fail "Plugin was not installed"
    assert_codex_install
    [ ! -f "$STATE_DIR/exapump_version" ] || fail "exapump should not be installed without release metadata"
    echo "$output" | grep -q "Could not determine latest exapump version" || fail "Expected exapump lookup warning"
    pass "Install continued after exapump release lookup failed"
    ;;
  idempotent)
    assert_codex_install
    echo "$output" | grep -q "Updating" || fail "Expected 'Updating' in output"
    echo "$output" | grep -q "v0.6.0" || fail "Expected marketplace version 0.6.0 in output"
    echo "$output" | grep -q "up to date" || fail "Expected exapump up-to-date message"
    pass "Idempotent re-run succeeded"
    ;;
  update)
    assert_codex_install
    version="$(cat "$STATE_DIR/plugin_version")"
    [ "$version" = "0.5.0" ] || fail "Expected plugin version 0.5.0 after update, got $version"
    echo "$output" | grep -q "v0.6.0" || fail "Expected marketplace version 0.6.0 in output"
    echo "$output" | grep -q "Updating exapump" || fail "Expected explicit exapump update"
    grep -q '/v0.6.0/install.sh$' "$STATE_DIR/exapump_install_url" || fail "Expected a release-tag-pinned exapump installer URL"
    pass "Update from older version succeeded"
    ;;
  fresh-claude)
    [ -f "$STATE_DIR/marketplace" ] || fail "Marketplace was not added"
    [ -f "$STATE_DIR/plugin" ] || fail "Plugin was not installed"
    [ ! -f "$STATE_DIR/codex_skills" ] || fail "Codex skills should not be installed"
    echo "$output" | grep -q "Adding marketplace" || fail "Expected 'Adding marketplace' in output"
    echo "$output" | grep -q "Installing plugin" || fail "Expected 'Installing plugin' in output"
    pass "Fresh install (Claude Code only) succeeded"
    ;;
  fresh-codex)
    [ ! -f "$STATE_DIR/marketplace" ] || fail "Claude marketplace should not be added"
    [ ! -f "$STATE_DIR/plugin" ] || fail "Claude plugin should not be installed"
    assert_codex_install
    echo "$output" | grep -q "installing all Exasol skills globally for OpenAI Codex" || fail "Expected Codex install message"
    pass "Fresh install (Codex only) succeeded"
    ;;
esac
