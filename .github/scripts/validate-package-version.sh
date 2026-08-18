#!/bin/sh

set -eu

MODE=${1:-}
RELEASE_TAG=${2:-}

fail() {
    if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
        printf '::error::%s\n' "$1" >&2
    else
        printf 'Error: %s\n' "$1" >&2
    fi
    exit 1
}

is_version() {
    printf '%s\n' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
}

is_newer() {
    awk -v candidate="$1" -v existing="$2" 'BEGIN {
        split(candidate, a, ".")
        split(existing, b, ".")
        for (i = 1; i <= 3; i++) {
            if (a[i] + 0 > b[i] + 0) exit 0
            if (a[i] + 0 < b[i] + 0) exit 1
        }
        exit 1
    }'
}

case "$MODE" in
    "") ;;
    --newer-than-tags) [ -z "$RELEASE_TAG" ] || fail "Unexpected argument '$RELEASE_TAG'" ;;
    --release-tag) [ -n "$RELEASE_TAG" ] || fail "Missing tag after --release-tag" ;;
    *) fail "Usage: $0 [--newer-than-tags | --release-tag <tag>]" ;;
esac

command -v jq >/dev/null 2>&1 || fail "jq is required to validate package versions"
if [ "$MODE" = "--newer-than-tags" ] || [ "$MODE" = "--release-tag" ]; then
    command -v git >/dev/null 2>&1 || fail "git is required to compare release tags"
fi

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$REPO_ROOT"

MANIFEST_VERSION=$(jq -er '.metadata.version' .claude-plugin/marketplace.json) \
    || fail "Could not read the marketplace manifest version"
PLUGIN_VERSION=$(jq -er '.version' plugins/exasol/.claude-plugin/plugin.json) \
    || fail "Could not read the plugin manifest version"
CHANGELOG_VERSION=$(sed -n 's/^## v\([0-9][0-9.]*\)$/\1/p' CHANGELOG.md | sed -n '1p')

is_version "$MANIFEST_VERSION" || fail "Invalid package version '$MANIFEST_VERSION'"
[ "$MANIFEST_VERSION" = "$PLUGIN_VERSION" ] \
    || fail "Marketplace version '$MANIFEST_VERSION' does not match plugin version '$PLUGIN_VERSION'"
[ "$MANIFEST_VERSION" = "$CHANGELOG_VERSION" ] \
    || fail "Package version '$MANIFEST_VERSION' does not match latest changelog version '${CHANGELOG_VERSION:-missing}'"

if [ "$MODE" = "--release-tag" ]; then
    [ "$RELEASE_TAG" = "v$MANIFEST_VERSION" ] \
        || fail "Tag '$RELEASE_TAG' does not match package version '$MANIFEST_VERSION'"
fi

if [ "$MODE" = "--newer-than-tags" ] || [ "$MODE" = "--release-tag" ]; then
    for EXISTING_TAG in $(git tag -l 'v*'); do
        [ "$EXISTING_TAG" = "$RELEASE_TAG" ] && continue
        EXISTING_VERSION=${EXISTING_TAG#v}
        is_version "$EXISTING_VERSION" || continue
        is_newer "$MANIFEST_VERSION" "$EXISTING_VERSION" \
            || fail "Package version '$MANIFEST_VERSION' is not newer than existing tag '$EXISTING_TAG'"
    done
fi

printf "Package version '%s' is valid.\n" "$MANIFEST_VERSION"
