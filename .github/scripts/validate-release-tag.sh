#!/bin/sh

set -eu

TAG=${1:-}
TAG_COMMIT=${2:-}
MAIN_REF=${3:-origin/main}

fail() {
    if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
        printf '::error::%s\n' "$1" >&2
    else
        printf 'Error: %s\n' "$1" >&2
    fi
    exit 1
}

[ -n "$TAG" ] || fail "Usage: $0 <tag> <tag-commit> [main-ref]"
[ -n "$TAG_COMMIT" ] || fail "Usage: $0 <tag> <tag-commit> [main-ref]"
command -v git >/dev/null 2>&1 || fail "git is required to validate release tags"

case "$TAG" in
    v*) VERSION=${TAG#v} ;;
    *) fail "Release tag '$TAG' must start with 'v'" ;;
esac

[ -n "$VERSION" ] || fail "Release tag must include a version after 'v'"

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$REPO_ROOT"

TAG_REF_COMMIT=$(git rev-parse --verify "refs/tags/${TAG}^{commit}" 2>/dev/null) \
    || fail "Release tag '$TAG' does not exist"
EVENT_COMMIT=$(git rev-parse --verify "${TAG_COMMIT}^{commit}" 2>/dev/null) \
    || fail "Tag event commit '$TAG_COMMIT' is not a valid commit"
[ "$TAG_REF_COMMIT" = "$EVENT_COMMIT" ] \
    || fail "Tag '$TAG' does not point to commit '$TAG_COMMIT'"
git rev-parse --verify "${MAIN_REF}^{commit}" >/dev/null 2>&1 \
    || fail "Main reference '$MAIN_REF' does not point to a valid commit"
git merge-base --is-ancestor "$EVENT_COMMIT" "${MAIN_REF}^{commit}" \
    || fail "Tag '$TAG' does not point to a commit on main"

sh .github/scripts/validate-package-version.sh --release-tag "$TAG"

printf "Release tag '%s' is valid.\n" "$TAG"
