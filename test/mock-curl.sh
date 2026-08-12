#!/bin/sh
# Mock curl for testing install.sh
# Handles the GitHub API latest-release endpoint and the exapump install script.

STATE_DIR="${STATE_DIR:-/tmp/mock-claude-state}"
MOCK_EXAPUMP_LATEST="${MOCK_EXAPUMP_LATEST:-v0.6.0}"
MOCK_MARKETPLACE_VERSION="${MOCK_MARKETPLACE_VERSION:-0.6.0}"

# Extract the URL from args (last non-flag argument)
url=""
output_file=""
expect_output=0
for arg in "$@"; do
  case "$arg" in
    -o)  expect_output=1 ;;
    --*) ;;
    -*)  ;;
    *)
      if [ "$expect_output" -eq 1 ]; then
        output_file="$arg"
        expect_output=0
      else
        url="$arg"
      fi
      ;;
  esac
done

emit() {
  if [ -n "$output_file" ]; then
    cat > "$output_file"
  else
    cat
  fi
}

case "$url" in
  *api.github.com/repos/exasol-labs/exapump/releases/latest*)
    if [ "${MOCK_EXAPUMP_API_FAILURE:-no}" = "yes" ]; then
      exit 22
    fi
    emit <<EOF
{"tag_name": "${MOCK_EXAPUMP_LATEST}", "name": "${MOCK_EXAPUMP_LATEST}"}
EOF
    ;;
  *raw.githubusercontent.com/exasol-labs/exapump/v*/install.sh*)
    # Simulate exapump installer: write the latest version to state
    printf '%s\n' "$url" > "$STATE_DIR/exapump_install_url"
    {
      echo "#!/bin/sh"
      echo "echo 'Installing exapump ${MOCK_EXAPUMP_LATEST}...'"
      echo "echo '${MOCK_EXAPUMP_LATEST}' > '${STATE_DIR}/exapump_version'"
    } | emit
    ;;
  *raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/.claude-plugin/marketplace.json*)
    emit <<EOF
{"name": "exasol-skills", "metadata": {"version": "${MOCK_MARKETPLACE_VERSION}"}, "plugins": []}
EOF
    ;;
  *)
    # Pass through — should not happen in tests
    echo "mock-curl: unhandled URL: $url" >&2
    exit 1
    ;;
esac
