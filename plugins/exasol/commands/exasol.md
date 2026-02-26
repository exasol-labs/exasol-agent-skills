# /exasol Command

Execute SQL queries or perform database tasks against an Exasol instance using the `exapump` CLI tool.

## Usage

```
/exasol <SQL query or task description>
```

## Arguments

The argument can be either:
- A **SQL query** to execute directly: `/exasol SELECT * FROM my_table LIMIT 10`
- A **task description** to get guided help: `/exasol upload a CSV file to a new table`

## Behavior

When invoked:

1. **Check connection**: Test connectivity with `exapump sql "SELECT 1"`. If it fails, run `exapump profile list` to check available profiles. If profiles exist, ask the user which to use and retry with `--profile <name>`. If no profiles exist, tell the user to run `exapump profile add default`.

2. **If the argument is a SQL query** (starts with SELECT, CREATE, DROP, INSERT, UPDATE, DELETE, MERGE, IMPORT, EXPORT, ALTER, GRANT, etc.):
   - Execute it via `exapump sql "<query>"`
   - Display results
   - If the query fails, diagnose using Exasol SQL knowledge (check reserved keywords, identifier casing, missing NOT NULL on UNIQUE, etc.)

3. **If the argument is a task description**:
   - Determine the right approach (exapump command vs SQL IMPORT/EXPORT)
   - Generate and execute the appropriate commands
   - For uploads: use `exapump upload` with `--dry-run` first to preview schema
   - For exports: use `exapump export` with appropriate format

4. **On errors**: Apply Exasol SQL knowledge to diagnose and fix issues. Common causes:
   - Reserved keyword used as identifier — verify by running `exapump sql "SELECT * FROM EXA_SQL_KEYWORDS WHERE KEYWORD = '<word>'"`, then double-quote the identifier
   - Uppercase identifier mismatch
   - Missing NOT NULL on UNIQUE constraint columns
   - Using unsupported syntax from other databases
   - Using TIME data type

## Examples

```
/exasol SELECT COUNT(*) FROM my_schema.my_table
/exasol CREATE TABLE analytics.events (id DECIMAL(18,0), event_name VARCHAR(200), created_at TIMESTAMP)
/exasol upload sales_data.csv to analytics.sales
/exasol export the users table to parquet with zstd compression
/exasol show me the schema of the orders table
/exasol is "profile" a reserved keyword in Exasol?
```
