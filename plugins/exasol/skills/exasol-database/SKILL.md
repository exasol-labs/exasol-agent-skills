---
name: exasol-database
description: Exasol database interaction via exapump CLI and Exasol SQL. Covers file upload/export, SQL queries, and Exasol-specific SQL behavior including data types, reserved keywords, and constraints.
---

# Exasol Database Skill

Trigger when the user mentions **Exasol**, **exapump**, **database import/export**, **CSV/Parquet upload**, **Exasol SQL**, **IMPORT INTO**, **EXPORT INTO**, **EXA_**, or any Exasol database interaction.

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

2. **Remote files** (S3, Azure Blob, GCS):
   - Load: `references/exasol-sql.md` (IMPORT/EXPORT + connection objects)

3. **SQL execution** (queries, DDL, DML, schema inspection):
   - Load: `references/exapump-reference.md` (CLI usage)
   - Load: `references/exasol-sql.md` (core SQL behavior)

4. **Table design** (DISTRIBUTE BY, PARTITION BY, CREATE TABLE layout):
   - Load: `references/table-design.md`

5. **Query profiling / performance** (slow queries, data skew, REORGANIZE):
   - Load: `references/query-profiling.md`

6. **Analytics / window functions** (ROW_NUMBER, RANK, LAG/LEAD, QUALIFY, GROUPING SETS):
   - Load: `references/analytics-qualify.md`

7. **Virtual Schemas** (external data sources, adapter scripts):
   - Load: `references/virtual-schemas.md`

8. **ETL / staging pipelines** (MERGE staging, SCD Type 2, REJECT LIMIT):
   - Load: `references/merge-staging.md`

Multiple routes can apply — load all that match. For example, designing a table for an ETL pipeline → load table-design.md + merge-staging.md.

9. **Before writing any SQL** (applies to routes 2–8):
   - Check all identifiers (column names, table names, aliases) against the **reserved keyword list in `references/exasol-sql.md`** (Common Traps section)
   - Double-quote any identifier that appears in that list
   - If a query fails with a syntax error that may be caused by a reserved keyword, fetch the live list: `exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD"`
   - This is critical — Exasol reserves many common words (e.g., `YEAR`, `PROFILE`, `FILE`, `POSITION`) that are unreserved in other databases

## Related Skills

This skill handles core database interaction: connecting, uploading/exporting files, SQL execution, and table design.
For UDF development and Script Language Containers, the **exasol-udfs** skill provides specialized guidance
and will activate automatically when relevant.
