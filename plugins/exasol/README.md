# Exasol Plugin for Claude Code

A Claude Code plugin that helps you interact with Exasol databases using the `exapump` CLI tool.

## Features

- **Upload** CSV and Parquet files to Exasol tables
- **Query** Exasol with SQL and get results in CSV or JSON
- **Export** tables or query results to CSV or Parquet files
- **Exasol SQL knowledge** — understands Exasol-specific quirks, reserved keywords, and data type differences
- **Error diagnosis** — automatically identifies common Exasol SQL errors (reserved keywords, identifier casing, constraint limitations)

## Skill

### exasol-database

The main skill that provides comprehensive knowledge about:
- exapump CLI usage (upload, sql, export, interactive)
- Exasol SQL differences from standard SQL
- Reserved keywords unique to Exasol
- Remote data loading via S3/Azure/GCS
- Common data workflows

**Triggers on:** mentions of Exasol, exapump, database import/export, CSV/Parquet loading, Exasol SQL, EXA_ system tables

## Slash Command

### `/exasol`

Run SQL queries or describe tasks to execute against an Exasol database.

```
/exasol SELECT * FROM my_table LIMIT 10
/exasol upload data.csv to my_schema.my_table
```

## Prerequisites

1. Install exapump:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh
   ```

2. Set up your connection:
   ```bash
   export EXAPUMP_DSN="exasol://user:password@host:port"
   ```
