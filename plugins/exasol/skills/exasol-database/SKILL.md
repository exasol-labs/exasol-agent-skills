---
name: exasol-database
description: Exasol database interaction via exapump CLI and Exasol SQL. Covers SQL queries, schema inspection, table design, query profiling, analytics, and Exasol-specific SQL behavior outside the dedicated import/export and virtual-schema skills.
---

# Exasol Database Skill

Trigger when the user asks for **Exasol database interaction**, **exapump**, **Exasol SQL**, **EXA_** system views, schemas, tables, or query execution outside the dedicated import/export and virtual-schema skills.

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

2. **Table design** (DISTRIBUTE BY, PARTITION BY, CREATE TABLE layout):
   - Load: `references/table-design.md`

3. **Query profiling / performance** (slow queries, data skew, REORGANIZE):
   - Load: `references/query-profiling.md`

4. **Analytics / window functions** (ROW_NUMBER, RANK, LAG/LEAD, QUALIFY, GROUPING SETS):
   - Load: `references/analytics-qualify.md`

5. **BucketFS file management** (upload/download/list/delete files in BucketFS, bfsdefault, bucket paths):
   - Activate the **exasol-bucketfs** skill for guidance

6. **UDF development** (CREATE SCRIPT, ExaIterator, SCALAR/SET, Script Language Containers, SLC, exaslct):
   - Activate the **exasol-udfs** skill for guidance

Multiple routes can apply — load all that match.

7. **Before writing any SQL** (applies to routes 1–4):
   - **Always double-quote every identifier** (column names, table names, schema names) in SELECT, FROM, WHERE, GROUP BY, ORDER BY, and JOIN clauses — without exception
   - This preserves mixed-case names and prevents reserved-keyword errors in a single rule
   - Do NOT quote SQL keywords, functions, or aliases — only object identifiers
   - If a query fails with a syntax error, fetch the live reserved keyword list: `exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD"`

## Related Skills

This skill handles core database interaction: connecting, SQL execution, schema inspection, and table design.
For direct native `IMPORT` and `EXPORT` plus local file movement, the **exasol-import-export** skill provides specialized guidance and will activate automatically when relevant.
For BucketFS file management (upload, download, list, delete), the **exasol-bucketfs** skill provides specialized guidance and will activate automatically when relevant.
For UDF development and Script Language Containers, the **exasol-udfs** skill provides specialized guidance and will activate automatically when relevant.
