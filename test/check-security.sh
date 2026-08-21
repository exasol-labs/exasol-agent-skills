#!/bin/sh
set -eu

SCAN_STATUS=0
git grep -lE \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'ASIA[0-9A-Z]{16}' \
  -e '-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----' \
  -e '(ghp|gho|github_pat)_[A-Za-z0-9_]+' \
  -e 'glpat-[A-Za-z0-9_-]{20,}' \
  -e 'sk-(proj-)?[A-Za-z0-9_-]{20,}' \
  -e 'AIza[0-9A-Za-z_-]{35}' \
  -e 'xox[baprs]-[A-Za-z0-9-]+' \
  -e 'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}' \
  -- ':!test/check-security.sh' || SCAN_STATUS=$?

case "$SCAN_STATUS" in
  0)
    echo "Credential-like material found in tracked files." >&2
    exit 1
    ;;
  1)
    echo "No credential-like material found in tracked files."
    ;;
  *)
    echo "Credential scan failed (git grep exited with status $SCAN_STATUS)." >&2
    exit "$SCAN_STATUS"
    ;;
esac
