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

1. **Check connection**: Verify `EXAPUMP_DSN` is set or a `--dsn` is available. If not, help the user set it up with the format `exasol://user:password@host:port`.

2. **If the argument is a SQL query** (starts with SELECT, CREATE, DROP, INSERT, UPDATE, DELETE, MERGE, IMPORT, EXPORT, ALTER, GRANT, etc.):
   - Execute it via `exapump sql "<query>"`
   - Display results
   - If the query fails, diagnose using Exasol SQL quirks knowledge (check reserved keywords, identifier casing, missing NOT NULL on UNIQUE, etc.)

3. **If the argument is a task description**:
   - Determine the right approach (exapump command vs SQL IMPORT/EXPORT)
   - Generate and execute the appropriate commands
   - For uploads: use `exapump upload` with `--dry-run` first to preview schema
   - For exports: use `exapump export` with appropriate format

4. **On errors**: Apply knowledge of Exasol SQL differences to diagnose and fix issues. Common causes:
   - Reserved keyword used as identifier — verify by running `exapump sql "SELECT * FROM EXA_SQL_KEYWORDS WHERE KEYWORD = '<word>'"`, then double-quote the identifier
   - Uppercase identifier mismatch
   - Missing NOT NULL on UNIQUE constraint columns
   - Using unsupported syntax from other databases
   - Using TIME data type
   - Missing TLS parameters in DSN (Docker setups need `?tls=true&validate_certificate=false`)

## Examples

```
/exasol SELECT COUNT(*) FROM my_schema.my_table
/exasol CREATE TABLE analytics.events (id DECIMAL(18,0), event_name VARCHAR(200), created_at TIMESTAMP)
/exasol upload sales_data.csv to analytics.sales
/exasol export the users table to parquet with zstd compression
/exasol show me the schema of the orders table
/exasol is "profile" a reserved keyword in Exasol?
```
