---
name: exasol-database
description: Exasol database interaction via exapump CLI and Exasol SQL. Covers file upload/export, SQL queries, and Exasol-specific SQL behavior including data types, reserved keywords, and constraints.
---

# Exasol Database Skill

Trigger when the user mentions **Exasol**, **exapump**, **database import/export**, **CSV/Parquet upload**, **Exasol SQL**, **IMPORT INTO**, **EXPORT INTO**, **EXA_**, or any Exasol database interaction.

## Routing Algorithm

Determine the task type, then load the appropriate references:

1. **If the task involves local files** (upload CSV/Parquet to Exasol, or export query results to local files):
   - Use the **exapump CLI** (`exapump upload`, `exapump export`)
   - Load `references/exapump-reference.md`

2. **If the task involves remote files** (S3, Azure Blob, GCS — preferred for large data volumes):
   - Use **SQL IMPORT/EXPORT statements** with connection objects
   - Load `references/exasol-sql.md`

3. **If the task involves SQL execution** (queries, DDL, DML, schema inspection):
   - Invoke via **`exapump sql`** → load `references/exapump-reference.md` for CLI usage
   - Load `references/exasol-sql.md` for Exasol SQL behavior (data types, reserved keywords, constraints, identifiers)
