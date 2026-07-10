---
name: exasol-database
description: Exasol database interaction via exapump CLI and Exasol SQL. Covers SQL queries, file upload/export, table design, import/export, query profiling, and Exasol-specific SQL behavior outside the dedicated virtual-schema skill.
---

# Exasol Database Skill

Trigger when the user asks for **Exasol database interaction**, **exapump**, **database import/export**, **CSV/Parquet upload**, **Exasol SQL**, **IMPORT INTO**, **EXPORT INTO**, **EXA_** system views, schemas, tables, or query execution outside the dedicated virtual-schema skill.

## Step 0: Establish Connection

Ensure a working exapump profile before proceeding:

1. **If the user mentions a specific profile name** → test it: `exapump sql --profile <name> "SELECT 1"` (always place `--profile` after the subcommand). On success, use `--profile <name>` on all subsequent commands.
2. **Otherwise** → test the default profile: `exapump sql "SELECT 1"`.
3. **On success** → proceed. No further connection setup needed.
4. **On failure** → run `exapump profile list` to check available profiles.
   - If profiles exist → present the list and ask the user which to use, then retry with `exapump sql --profile <name> "SELECT 1"` (always place `--profile` after the subcommand).
   - If no profiles → tell the user to run `exapump profile add default` to create one, then retry.
5. **Never** read or reference the exapump configuration file — it contains credentials.

## Routing Algorithm

After the connection is established, determine the task type and load **only** the references needed:

1. **Local files** (upload CSV/Parquet, export to local files):
   - Load: `references/exapump-reference.md`
   - Load: `references/import-export.md` (decision tree, connection objects)

2. **Remote files / bulk loading** (S3, Azure, GCS, FTP, HTTP — IMPORT/EXPORT):
   - Load: `references/import-export.md`

3. **SQL execution** (queries, DDL, DML, schema inspection):
   - Load: `references/exapump-reference.md` (CLI usage)
   - Load: `references/exasol-sql.md` (core SQL behavior)
   - Load: `references/exasol-grammar.md` for the **exact statement syntax** (SELECT/DQL, DDL, DML, DCL, IMPORT/EXPORT, session & admin) — the EBNF the docs.exasol.com syntax diagrams are generated from. Consult it before inventing syntax or when unsure a clause exists. **Read only the section you need** — it is large.
   - Load: `references/exasol-grammar-functions.md` for **built-in function, operator, predicate, literal, and data-type syntax** (e.g. the exact argument order of a function). Same EBNF source, split out so statement lookups don't pull in the full function catalog.
   - Load: `references/exasol-reserved-keywords.md` and **ingest the full list before designing queries** — every reserved word (pinned to Exasol 2026.1.0) must be double-quoted when used as an identifier. On a keyword-related syntax error, re-query the running DB (see route 10) in case the file has drifted from the DB version.

4. **Table design** (DISTRIBUTE BY, PARTITION BY, CREATE TABLE layout):
   - Load: `references/table-design.md`

5. **Query profiling / performance** (slow queries, data skew, REORGANIZE):
   - Load: `references/query-profiling.md`

6. **Analytics / window functions** (ROW_NUMBER, RANK, LAG/LEAD, QUALIFY, GROUPING SETS):
   - Load: `references/analytics-qualify.md`
   - Load: `references/exasol-grammar-functions.md` for exact analytic-function and `OVER (…)` window-clause syntax

7. **BucketFS file management** (upload/download/list/delete files in BucketFS, bfsdefault, bucket paths):
   - Activate the **exasol-bucketfs** skill for guidance

8. **UDF development** (CREATE SCRIPT, ExaIterator, SCALAR/SET, Script Language Containers, SLC, exaslct):
   - Activate the **exasol-udfs** skill for guidance

Multiple routes can apply — load all that match.

10. **Before writing any SQL** (applies to routes 2–7):
   - **Ingest `references/exasol-reserved-keywords.md` before designing queries** — load the reserved-word list (pinned to Exasol 2026.1.0) up front so you quote reserved identifiers from the start rather than discovering them through errors
   - **Always double-quote every identifier** (column names, table names, schema names) in SELECT, FROM, WHERE, GROUP BY, ORDER BY, and JOIN clauses — without exception
   - This preserves mixed-case names and prevents reserved-keyword errors in a single rule
   - Do NOT quote SQL keywords, functions, or aliases — only object identifiers
   - If a query fails with a syntax error that looks like an unquoted reserved word, do **not** trust the pinned file blindly — the DB may be newer or older than 2026.1.0 and the list can drift either way. Fetch the authoritative list for the running version and reconcile: `exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD"`
   - For the exact shape of any clause (optional parts, ordering, comma-lists), consult `references/exasol-grammar.md` (statements) or `references/exasol-grammar-functions.md` (functions / predicates / literals / data types) rather than guessing from examples.

## Related Skills

This skill handles core database interaction: connecting, uploading/exporting files, SQL execution, and table design.
For federated read-only access, adapter setup, `EXPLAIN VIRTUAL`, and virtual-schema troubleshooting, the **exasol-jdbc-virtual-schemas**, **exasol-document-virtual-schemas**, and **exasol-virtual-schema-adapter-development** skills provide specialized guidance and will activate automatically when relevant.
For BucketFS file management (upload, download, list, delete), the **exasol-bucketfs** skill provides specialized guidance and will activate automatically when relevant.
For UDF development and Script Language Containers, the **exasol-udfs** skill provides specialized guidance and will activate automatically when relevant.
