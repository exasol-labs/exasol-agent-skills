---
name: exasol-database
description: Exasol database interaction via exapump CLI and Exasol SQL. Covers SQL queries, file upload/export, table design, import/export, query profiling, and Exasol-specific SQL behavior.
---

# Exasol Database Skill

Trigger when the user asks for **Exasol database interaction**, **exapump**, **database import/export**, **CSV/Parquet upload**, **Exasol SQL**, **IMPORT INTO**, **EXPORT INTO**, **EXA_** system views, schemas, tables, or query execution.

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
   - Load: `references/exasol-grammar.md` when you need the **exact, complete syntax** of a statement or clause — the full EBNF grammar (SELECT, DDL, DML, DCL, IMPORT/EXPORT, functions). Consult it before inventing syntax or when unsure a keyword/clause exists; it is the authoritative source the docs.exasol.com syntax diagrams are generated from.
   - Load: `references/exasol-reserved-keywords.md` to check whether a specific identifier is a **reserved keyword** (must be double-quoted). Full list from `EXA_SQL_KEYWORDS WHERE RESERVED`.

4. **Table design** (DISTRIBUTE BY, PARTITION BY, CREATE TABLE layout):
   - Load: `references/table-design.md`

5. **Query profiling / performance** (slow queries, data skew, REORGANIZE):
   - Load: `references/query-profiling.md`

6. **Analytics / window functions** (ROW_NUMBER, RANK, LAG/LEAD, QUALIFY, GROUPING SETS):
   - Load: `references/analytics-qualify.md`

7. **Virtual Schemas** (external data sources, adapter scripts):
   - Load: `references/virtual-schemas.md`

8. **BucketFS file management** (upload/download/list/delete files in BucketFS, bfsdefault, bucket paths):
   - Activate the **exasol-bucketfs** skill for guidance

9. **UDF development** (CREATE SCRIPT, ExaIterator, SCALAR/SET, Script Language Containers, SLC, exaslct):
   - Activate the **exasol-udfs** skill for guidance

Multiple routes can apply — load all that match.

10. **Before writing any SQL** (applies to routes 2–7):
   - **Always double-quote every identifier** (column names, table names, schema names) in SELECT, FROM, WHERE, GROUP BY, ORDER BY, and JOIN clauses — without exception
   - This preserves mixed-case names and prevents reserved-keyword errors in a single rule
   - Do NOT quote SQL keywords, functions, or aliases — only object identifiers
   - If a query fails with a syntax error, check `references/exasol-reserved-keywords.md`, or fetch the live list: `exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD"`
   - For the exact shape of any clause (optional parts, ordering, comma-lists), consult `references/exasol-grammar.md` rather than guessing from examples.

## Related Skills

This skill handles core database interaction: connecting, uploading/exporting files, SQL execution, and table design.
For BucketFS file management (upload, download, list, delete), the **exasol-bucketfs** skill provides specialized guidance and will activate automatically when relevant.
For UDF development and Script Language Containers, the **exasol-udfs** skill provides specialized guidance and will activate automatically when relevant.
