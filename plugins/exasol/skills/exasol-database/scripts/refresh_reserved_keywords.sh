#!/usr/bin/env bash
# Regenerates references/exasol-reserved-keywords.md from a live Exasol database.
#
# Reserved keywords live in the EXA_SQL_KEYWORDS system table and are
# version-specific, so — unlike the grammar — this list can only come from a
# running database, not a public repo. Point it at any Exasol instance.
#
# Usage:
#   ./refresh_reserved_keywords.sh --profile <name>
#   ./refresh_reserved_keywords.sh --dsn 'exasol://user:pwd@host:port' [--certificate-fingerprint <sha256>]
set -euo pipefail

OUT="$(cd "$(dirname "$0")/../references" && pwd)/exasol-reserved-keywords.md"
CONN=("$@")   # pass exapump connection flags straight through

q() { exapump sql "${CONN[@]}" -f json "$1" 2>/dev/null; }

VERSION="$(q "SELECT PARAM_VALUE AS V FROM EXA_METADATA WHERE PARAM_NAME='databaseProductVersion'" \
  | python3 -c 'import sys,json,re;m=re.search(r"\[.*\]",sys.stdin.read(),re.S);print(json.loads(m.group(0))[0]["V"])')"

KWFILE="$(mktemp)"; trap 'rm -f "$KWFILE"' EXIT
q "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD" \
  | python3 -c 'import sys,json,re;m=re.search(r"\[.*\]",sys.stdin.read(),re.S);[print(r["KEYWORD"]) for r in json.loads(m.group(0))]' \
  | sort -u > "$KWFILE"

COUNT="$(wc -l < "$KWFILE")"
WRAPPED="$(paste -sd, "$KWFILE" | sed 's/,/, /g' | fold -s -w 78 | sed 's/[[:space:]]*$//')"

cat > "$OUT" <<EOF
# Exasol Reserved Keywords

> **Source of truth.** The complete list of **reserved** SQL keywords, pulled
> verbatim from the \`EXA_SQL_KEYWORDS\` system table (\`WHERE RESERVED = TRUE\`).
> A reserved keyword **cannot** be used as an unquoted identifier (table,
> column, schema, alias name) — it must be double-quoted, e.g. \`"VALUE"\`,
> \`"YEAR"\`, \`"POSITION"\`.
>
> - **DB version:** $VERSION (matches the \`master\`/v8 grammar in \`exasol-grammar.md\`)
> - **Count:** $COUNT reserved keywords
> - **Refresh:** \`scripts/refresh_reserved_keywords.sh <connection-flags>\` (queries a live DB; do not hand-edit)

## How to use this

- **Writing SQL:** if an identifier appears in this list, double-quote it. The
  safe blanket rule (see the skill's SKILL.md) is to double-quote *every*
  object identifier — this list explains *why* it's necessary and lets you
  check a specific name.
- **Non-reserved keywords** (e.g. many function names) are usable as unquoted
  identifiers and are **not** listed here. For the full picture query
  \`SELECT KEYWORD, RESERVED FROM EXA_SQL_KEYWORDS ORDER BY KEYWORD\`.
- This list is version-specific. It rarely changes between releases, but the
  live table on the target database is always authoritative:
  \`SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD\`.

## Reserved keywords ($COUNT)

\`\`\`text
$WRAPPED
\`\`\`
EOF

echo "Wrote $OUT ($COUNT keywords, DB $VERSION)"
