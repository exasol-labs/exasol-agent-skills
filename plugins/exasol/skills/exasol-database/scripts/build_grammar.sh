#!/usr/bin/env bash
# Assembles the complete Exasol SQL grammar reference from the authoritative
# EBNF source at github.com/exasol/sql-syntax-diagrams (diagrams/*.bnf).
#
# The docs.exasol.com syntax diagrams are PNGs rendered from these .bnf files
# via Ebnf2ps. This script vendors the *text* source so agents read grammar,
# not images.
#
# Usage: ./build_grammar.sh [branch]   (branch: master = v8/2025, R7.1 = 7.1)
set -euo pipefail

REPO="exasol/sql-syntax-diagrams"
BRANCH="${1:-master}"
OUT="$(cd "$(dirname "$0")/../references" && pwd)/exasol-grammar.md"

SHA="$(gh api "repos/$REPO/commits/$BRANCH" --jq '.sha')"

# Fetch the .bnf sources for this commit into a temp dir.
BNF_DIR="$(mktemp -d)"
trap 'rm -rf "$BNF_DIR"' EXIT
fetch_bnf() {
  gh api "repos/$REPO/contents/diagrams/$1?ref=$SHA" --jq '.content' | base64 -d > "$BNF_DIR/$1"
}

# File order = logical reading order, not the repo's alphabetical listing.
# label|file
FILES=(
  "Query language (SELECT / DQL)|dql.bnf"
  "Data manipulation (INSERT / UPDATE / DELETE / MERGE / TRUNCATE — DML)|dml.bnf"
  "Data definition (CREATE / ALTER / DROP — DDL)|ddl.bnf"
  "Access control (GRANT / REVOKE / roles / privileges — DCL)|dcl.bnf"
  "Sessions, transactions & administration (DAL)|dal.bnf"
  "Bulk load & unload (IMPORT / EXPORT — ETL)|etl.bnf"
  "Built-in functions|functions.bnf"
  "Predicates & conditions|predicates.bnf"
  "Literals|literale.bnf"
  "Data types|datentypen.bnf"
  "Miscellaneous (expressions, identifiers, comments, hints)|sonstige.bnf"
)

{
cat <<EOF
# Exasol SQL Grammar (complete, authoritative)

> **Source of truth.** This is the *complete* supported Exasol SQL grammar in
> EBNF, vendored verbatim from
> [\`exasol/sql-syntax-diagrams\`](https://github.com/$REPO) — the same source
> the syntax-diagram images on docs.exasol.com are generated from (via
> \`Ebnf2ps\`). Prefer these rules over inferring syntax from examples: they
> define **every** legal clause, its ordering, and its repetition.
>
> - **DB version:** branch \`$BRANCH\` (\`master\` = major version 8, incl. 2025; \`R7.1\` = 7.1)
> - **Source commit:** \`$SHA\`
> - **Regenerate:** run \`scripts/build_grammar.sh $BRANCH\` (see below). Do not hand-edit.

## How to read this notation

The source uses the \`Ebnf2ps\` dialect. It is **not** standard EBNF — note the
repetition operators carefully:

| Notation | Meaning |
| --- | --- |
| \`a = b ;\` | definition of \`a\` |
| \`(a b)\` | group (only to scope \`\|\` or extend \`+\` / \`/\`) |
| \`a \| b\` | alternative (a **or** b) |
| \`[a]\` | optional (zero or one) |
| \`{a}\` | zero or more repetitions of a **single element** (⚠ reads right-to-left; never use for a group) |
| \`[(a b)+]\` | zero or more repetitions of a **group** |
| \`a+\` | one or more repetitions |
| \`a / sep\` | **one or more** repetitions of \`a\` separated by \`sep\` (e.g. \`expr / ","\` = comma-separated list) |
| \`[a / sep]\` | **zero or more** repetitions of \`a\` separated by \`sep\` |
| \`"string"\` | terminal — appears literally in the query (one terminal per token: \`"(" ")"\`, not \`"()"\`) |

⚠ The most common misreadings for an agent: \`/\` is a **separated list**, not
division; \`{a}\` is repetition of one element only. Keep both in mind.

Rule names in a few files are German (\`datentypen\` = data types, \`literale\` =
literals, \`sonstige\` = miscellaneous) — cosmetic; the terminals are the real SQL.
EOF

for entry in "${FILES[@]}"; do
  label="${entry%%|*}"
  file="${entry##*|}"
  fetch_bnf "$file"
  printf '\n---\n\n## %s\n\n<sub>source: `diagrams/%s`</sub>\n\n```ebnf\n' "$label" "$file"
  cat "$BNF_DIR/$file"
  printf '```\n'
done
} > "$OUT"

echo "Wrote $OUT ($(wc -c < "$OUT") bytes) from $REPO@$BRANCH ($SHA)"
