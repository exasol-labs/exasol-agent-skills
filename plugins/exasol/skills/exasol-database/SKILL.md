---
name: exasol-database
description: Exasol database interaction via exapump CLI and Exasol SQL. Covers SQL queries, schema inspection, table design, query profiling, analytics, and Exasol-specific SQL behavior outside **exasol-import** and **exasol-export**.
---

# Exasol Database Skill

Trigger when the user asks for **Exasol database interaction**, **exapump**, **Exasol SQL**, **EXA_** system views, schemas, tables, or query execution outside **exasol-import** and **exasol-export**.

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

1. **SQL execution** (queries, DDL, DML, schema inspection):
   - Load: `references/exapump-reference.md` (CLI usage)
   - Load: `references/exasol-sql.md` (core SQL behavior)
   - Load: `references/exasol-grammar.md` for the **exact statement syntax** (SELECT/DQL, DDL, DML, DCL, session & admin) — the EBNF the docs.exasol.com syntax diagrams are generated from. Consult it before inventing syntax or when unsure a clause exists. **Read only the section you need** — it is large.
   - Load: `references/exasol-grammar-functions.md` for **built-in function, operator, predicate, literal, and data-type syntax** (e.g. the exact argument order of a function). Same EBNF source, split out so statement lookups don't pull in the full function catalog.
   - Load: `references/exasol-reserved-keywords.md` and **ingest the full list before designing queries** — every reserved word (pinned to Exasol 2026.1.0) must be double-quoted when used as an identifier. On a keyword-related syntax error, re-query the running DB as described in **Before writing any SQL** in case the file has drifted from the DB version.

2. **Table design** (DISTRIBUTE BY, PARTITION BY, CREATE TABLE layout):
   - Load: `references/table-design.md`

3. **Query profiling / performance** (slow queries, data skew, REORGANIZE):
   - Load: `references/query-profiling.md`

4. **Analytics / window functions** (ROW_NUMBER, RANK, LAG/LEAD, QUALIFY, GROUPING SETS):
   - Load: `references/analytics-qualify.md`
   - Load: `references/exasol-grammar-functions.md` for exact analytic-function and `OVER (…)` window-clause syntax

5. **Virtual Schemas** (external data sources, adapter scripts):
   - Load: `references/virtual-schemas.md`

6. **BucketFS file management** (upload/download/list/delete files in BucketFS, bfsdefault, bucket paths):
   - Activate the **exasol-bucketfs** skill for guidance

7. **UDF development** (CREATE SCRIPT, ExaIterator, SCALAR/SET, Script Language Containers, SLC, exaslct):
   - Activate the **exasol-udfs** skill for guidance

Multiple routes can apply — load all that match.

8. **Before writing any SQL** (applies to routes 1–5):
   - **Ingest `references/exasol-reserved-keywords.md` before designing queries** — load the reserved-word list (pinned to Exasol 2026.1.0) up front so you quote reserved identifiers from the start rather than discovering them through errors
   - **Always double-quote every identifier** (column names, table names, schema names) in SELECT, FROM, WHERE, GROUP BY, ORDER BY, and JOIN clauses — without exception
   - This preserves mixed-case names and prevents reserved-keyword errors in a single rule
   - Do NOT quote SQL keywords, functions, or aliases — only object identifiers
   - If a query fails with a syntax error that looks like an unquoted reserved word, do **not** trust the pinned file blindly — the DB may be newer or older than 2026.1.0 and the list can drift either way. Fetch the authoritative list for the running version and reconcile: `exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD"`
   - For the exact shape of any clause (optional parts, ordering, comma-lists), consult `references/exasol-grammar.md` (statements) or `references/exasol-grammar-functions.md` (functions / predicates / literals / data types) rather than guessing from examples.

## Related Skills

This skill handles core database interaction: connecting, SQL execution, schema inspection, and table design.
For direct native `IMPORT` and local file movement into Exasol, use **exasol-import**.
For direct native `EXPORT` and local file movement out of Exasol, use **exasol-export**.
For BucketFS file management (upload, download, list, delete), the **exasol-bucketfs** skill provides specialized guidance and will activate automatically when relevant.
For UDF development and Script Language Containers, the **exasol-udfs** skill provides specialized guidance and will activate automatically when relevant.
