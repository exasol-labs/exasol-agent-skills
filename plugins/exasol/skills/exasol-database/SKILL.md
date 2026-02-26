---
name: exasol-database
description: Exasol database interaction via exapump CLI and Exasol SQL. Covers file upload/export, SQL queries, and Exasol-specific SQL behavior including data types, reserved keywords, and constraints.
---

# Exasol Database Skill

Trigger when the user mentions **Exasol**, **exapump**, **database import/export**, **CSV/Parquet upload**, **Exasol SQL**, **IMPORT INTO**, **EXPORT INTO**, **EXA_**, or any Exasol database interaction.

## Step 0: Establish Connection

Ensure a working exapump profile before proceeding:

1. **If the user mentions a specific profile name** → test it: `exapump --profile <name> sql "SELECT 1"`. On success, use `--profile <name>` on all subsequent commands.
2. **Otherwise** → test the default profile: `exapump sql "SELECT 1"`.
3. **On success** → proceed. No further connection setup needed.
4. **On failure** → run `exapump profile list` to check available profiles.
   - If profiles exist → present the list and ask the user which to use, then retry with `exapump --profile <name> sql "SELECT 1"`.
   - If no profiles → tell the user to run `exapump profile add default` to create one, then retry.
5. **Never** read or reference the exapump configuration file — it contains credentials.

## Routing Algorithm

After the connection is established, determine the task type and load the appropriate references:

1. **If the task involves local files** (upload CSV/Parquet to Exasol, or export query results to local files):
   - Use the **exapump CLI** (`exapump upload`, `exapump export`)
   - Load `references/exapump-reference.md`

2. **If the task involves remote files** (S3, Azure Blob, GCS — preferred for large data volumes):
   - Use **SQL IMPORT/EXPORT statements** with connection objects
   - Load `references/exasol-sql.md`

3. **If the task involves SQL execution** (queries, DDL, DML, schema inspection):
   - Invoke via **`exapump sql`** → load `references/exapump-reference.md` for CLI usage
   - Load `references/exasol-sql.md` for Exasol SQL behavior (data types, reserved keywords, constraints, identifiers)
