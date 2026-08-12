#!/bin/sh

set -eu

for TOOL in git mktemp; do
    command -v "$TOOL" >/dev/null 2>&1 || {
        printf 'Required test command not found: %s\n' "$TOOL" >&2
        exit 1
    }
done

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/release-tag-test.XXXXXX")
trap 'rm -rf -- "$TEST_ROOT"' EXIT HUP INT TERM

mkdir -p \
    "$TEST_ROOT/.claude-plugin" \
    "$TEST_ROOT/.github/scripts" \
    "$TEST_ROOT/plugins/exasol/.claude-plugin"
cp "$REPO_ROOT/.claude-plugin/marketplace.json" "$TEST_ROOT/.claude-plugin/marketplace.json"
cp "$REPO_ROOT/.github/scripts/validate-package-version.sh" "$TEST_ROOT/.github/scripts/validate-package-version.sh"
cp "$REPO_ROOT/.github/scripts/validate-release-tag.sh" "$TEST_ROOT/.github/scripts/validate-release-tag.sh"
cp "$REPO_ROOT/plugins/exasol/.claude-plugin/plugin.json" "$TEST_ROOT/plugins/exasol/.claude-plugin/plugin.json"
cp "$REPO_ROOT/CHANGELOG.md" "$TEST_ROOT/CHANGELOG.md"

cd "$TEST_ROOT"
git init -q -b main
git config user.name "Release Tag Test"
git config user.email "release-tag-test@example.com"
git config commit.gpgsign false
git config tag.gpgsign false
git add .
git commit -qm "Create test package"

git remote add origin "$TEST_ROOT"
git fetch -q origin main:refs/remotes/origin/main

VERSION=$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    plugins/exasol/.claude-plugin/plugin.json | sed -n '1p')
MAIN_COMMIT=$(git rev-parse HEAD)
MAIN_REF=origin/main
VALIDATOR=.github/scripts/validate-release-tag.sh
PACKAGE_VALIDATOR=.github/scripts/validate-package-version.sh

git tag v0.0.0
sh "$PACKAGE_VALIDATOR" --newer-than-tags
git tag "v$VERSION"
sh "$VALIDATOR" "v$VERSION" "$MAIN_COMMIT" "$MAIN_REF"

git switch -qc feature
printf 'feature commit\n' > feature.txt
git add feature.txt
git commit -qm "Create feature commit"
FEATURE_COMMIT=$(git rev-parse HEAD)
git switch -q main

git tag -f "v$VERSION" "$FEATURE_COMMIT" >/dev/null
if sh "$VALIDATOR" "v$VERSION" "$FEATURE_COMMIT" "$MAIN_REF"; then
    printf 'Expected an unmerged tagged commit to be rejected.\n' >&2
    exit 1
fi

git tag -f "v$VERSION" "$MAIN_COMMIT" >/dev/null
if sh "$VALIDATOR" "v$VERSION" "$FEATURE_COMMIT" "$MAIN_REF"; then
    printf 'Expected a mismatched event commit to be rejected.\n' >&2
    exit 1
fi

git tag v999.999.999 "$MAIN_COMMIT"
if sh "$VALIDATOR" v999.999.999 "$MAIN_COMMIT" "$MAIN_REF"; then
    printf 'Expected a mismatched version to be rejected.\n' >&2
    exit 1
fi
git tag -d v999.999.999 >/dev/null

cp plugins/exasol/.claude-plugin/plugin.json plugin.backup
sed 's/^\([[:space:]]*"version"[[:space:]]*:[[:space:]]*\)"[^"]*"/\1"999.999.999"/' \
    plugin.backup > plugins/exasol/.claude-plugin/plugin.json
if sh "$PACKAGE_VALIDATOR"; then
    printf 'Expected mismatched manifest versions to be rejected.\n' >&2
    exit 1
fi
mv plugin.backup plugins/exasol/.claude-plugin/plugin.json

cp CHANGELOG.md changelog.backup
awk 'BEGIN { changed = 0 }
    changed == 0 && /^## v[0-9]/ { $0 = "## v999.999.999"; changed = 1 }
    { print }' changelog.backup > CHANGELOG.md
if sh "$PACKAGE_VALIDATOR"; then
    printf 'Expected a mismatched changelog version to be rejected.\n' >&2
    exit 1
fi
mv changelog.backup CHANGELOG.md

git tag v999.999.999 "$MAIN_COMMIT"
git tag -d "v$VERSION" >/dev/null
if sh "$PACKAGE_VALIDATOR" --newer-than-tags; then
    printf 'Expected the PR version gate to reject a non-increasing version.\n' >&2
    exit 1
fi
git tag "v$VERSION" "$MAIN_COMMIT"
if sh "$PACKAGE_VALIDATOR" --release-tag "v$VERSION"; then
    printf 'Expected a non-increasing release version to be rejected.\n' >&2
    exit 1
fi

printf 'Release tag validation tests passed.\n'
