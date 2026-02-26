#!/bin/sh
# Mock curl for testing install.sh
# Handles the GitHub API latest-release endpoint and the exapump install script.

STATE_DIR="${STATE_DIR:-/tmp/mock-claude-state}"
MOCK_EXAPUMP_LATEST="${MOCK_EXAPUMP_LATEST:-v0.6.0}"

# Extract the URL from args (last non-flag argument)
url=""
for arg in "$@"; do
  case "$arg" in
    -*)  ;;
    *)   url="$arg" ;;
  esac
done

case "$url" in
  *api.github.com/repos/exasol-labs/exapump/releases/latest*)
    cat <<EOF
{"tag_name": "${MOCK_EXAPUMP_LATEST}", "name": "${MOCK_EXAPUMP_LATEST}"}
EOF
    ;;
  *raw.githubusercontent.com/exasol-labs/exapump/main/install.sh*)
    # Simulate exapump installer: write the latest version to state
    echo "#!/bin/sh"
    echo "echo 'Installing exapump ${MOCK_EXAPUMP_LATEST}...'"
    echo "echo '${MOCK_EXAPUMP_LATEST}' > '${STATE_DIR}/exapump_version'"
    ;;
  *)
    # Pass through — should not happen in tests
    echo "mock-curl: unhandled URL: $url" >&2
    exit 1
    ;;
esac
