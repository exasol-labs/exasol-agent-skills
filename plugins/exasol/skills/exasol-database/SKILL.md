# Exasol Database Skill

Use this skill whenever the user mentions **Exasol**, **exapump**, **database import**, **database export**, **CSV upload to database**, **Parquet loading**, **Exasol SQL**, **data ingestion**, **IMPORT INTO**, **EXPORT INTO**, **EXA_**, or wants to interact with an Exasol database in any way. Also trigger when the user mentions loading data files into a database table, running SQL against Exasol, or exporting query results. This skill is essential for any Exasol-related database work.

## Installation

exapump is a single-binary CLI. Install it:

```bash
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh
```

## Connection Setup

exapump uses a DSN (Data Source Name) connection string:

```
exasol://user:password@host:port[?param=value&...]
```

**DSN query parameters:**

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `tls` (or `use_tls`, `ssl`) | `true`/`false` | `false` | Enable TLS encryption |
| `validate_certificate` (or `verify_certificate`, `validateservercertificate`) | `true`/`false` | `true` | Validate server TLS certificate |
| `timeout` (or `connection_timeout`) | seconds | `30` | Connection timeout |
| `query_timeout` | seconds | `300` | Query execution timeout |

**For Docker / self-signed certificate setups**, you must enable TLS and disable certificate validation:

```
exasol://sys:exasol@localhost:8563?tls=true&validate_certificate=false
```

**Three ways to provide the DSN:**

1. **Flag:** `--dsn "exasol://sys:exasol@localhost:8563?tls=true&validate_certificate=false"`
2. **Environment variable:** `export EXAPUMP_DSN="exasol://sys:exasol@localhost:8563?tls=true&validate_certificate=false"`
3. **`.env` file** in the current directory with `EXAPUMP_DSN=exasol://...`

When `EXAPUMP_DSN` is set, you can omit the `--dsn` flag from all commands.

## When to Use exapump vs SQL IMPORT/EXPORT

| Scenario | Use | Why |
|----------|-----|-----|
| Upload local CSV/Parquet to Exasol | `exapump upload` | Simplest path, auto-creates table |
| Run ad-hoc SQL queries | `exapump sql` | Quick results in CSV/JSON |
| Export query results to file | `exapump export` | Supports CSV, Parquet, splitting |
| Interactive SQL session | `exapump interactive` | REPL for exploration |
| Load from S3/Azure/GCS | SQL `IMPORT` | exapump doesn't support remote sources |
| ETL within Exasol | SQL `IMPORT`/`EXPORT` | Server-side, no data leaves the cluster |
| Scheduled production pipelines | SQL `IMPORT`/`EXPORT` | Better for automation within Exasol |

## exapump Commands

### upload — Load files into a table

```bash
# Upload a CSV file (auto-creates table if it doesn't exist)
exapump upload data.csv --table my_schema.my_table --dsn "exasol://sys:exasol@localhost:8563"

# Preview the inferred schema without loading
exapump upload data.csv --table my_schema.my_table --dry-run --dsn "exasol://..."

# Upload multiple files
exapump upload part1.csv part2.csv --table my_schema.combined --dsn "exasol://..."

# Upload with custom delimiter (e.g., tab-separated)
exapump upload data.tsv --table my_schema.my_table --delimiter $'\t' --dsn "exasol://..."

# Upload with no header row
exapump upload data.csv --table my_schema.my_table --no-header --dsn "exasol://..."

# Custom NULL representation
exapump upload data.csv --table my_schema.my_table --null-value "NA" --dsn "exasol://..."

# Upload Parquet files
exapump upload data.parquet --table my_schema.my_table --dsn "exasol://..."
```

### sql — Execute SQL statements

```bash
# Run a query, get CSV output
exapump sql "SELECT * FROM my_schema.my_table LIMIT 10" --dsn "exasol://..."

# Get JSON output
exapump sql "SELECT * FROM my_schema.my_table" --format json --dsn "exasol://..."

# DDL statements (CREATE, DROP, etc.)
exapump sql "CREATE SCHEMA IF NOT EXISTS my_schema" --dsn "exasol://..."

# Read SQL from stdin
echo "SELECT 1" | exapump sql --dsn "exasol://..."

# Read SQL from a file
exapump sql < query.sql --dsn "exasol://..."
```

### export — Export data to files

```bash
# Export a table to CSV
exapump export --table my_schema.my_table --output data.csv --format csv --dsn "exasol://..."

# Export a query result to Parquet
exapump export --query "SELECT * FROM t WHERE col > 100" --output result.parquet --format parquet --dsn "exasol://..."

# Export with compression (Parquet only)
exapump export --table t --output data.parquet --format parquet --compression zstd --dsn "exasol://..."

# Split output into multiple files by row count
exapump export --table t --output data.csv --format csv --max-rows-per-file 1000000 --dsn "exasol://..."

# Split output by file size
exapump export --table t --output data.parquet --format parquet --max-file-size 500MB --dsn "exasol://..."

# Export without header row
exapump export --table t --output data.csv --format csv --no-header --dsn "exasol://..."
```

### interactive — SQL REPL

```bash
# Start interactive session
exapump interactive --dsn "exasol://..."
```

## Critical Exasol SQL Differences

These are the most important things to know when writing SQL for Exasol. **Getting these wrong causes hard-to-debug errors.**

### No TIME Data Type
Exasol has **no standalone TIME type**. Use `TIMESTAMP` or store times as `VARCHAR`.

### Identifiers Are UPPERCASE by Default
Unquoted identifiers are automatically uppercased. `CREATE TABLE foo(bar INT)` creates table `FOO` with column `BAR`. Use double-quotes for case-sensitive identifiers: `CREATE TABLE "foo"("bar" INT)`.

### No CHECK Constraints
Exasol does not support `CHECK` constraints. Validate data in application logic or use views.

### UNIQUE Constraints Cannot Include Nullable Columns
All columns in a UNIQUE constraint must be declared `NOT NULL`.

### BOOLEAN Is a Native Type
Exasol supports `BOOLEAN` natively (unlike Oracle). Values: `TRUE`, `FALSE`, `NULL`.

### PCRE2 Regular Expressions
Exasol uses PCRE2 syntax (not POSIX): `REGEXP_LIKE`, `REGEXP_INSTR`, `REGEXP_REPLACE`, `REGEXP_SUBSTR`.

### MINUS and EXCEPT
Exasol supports both `MINUS` (Oracle-compatible) and `EXCEPT` for set difference. Both work identically.

### Reserved Keywords
Exasol reserves many keywords beyond the SQL standard. Using them as unquoted identifiers causes syntax errors. **Always double-quote identifiers that might be reserved words:** `"PROFILE"`, `"RANDOM"`, etc.

**To check if a word is reserved, query the live database:**
```bash
# Check a specific word
exapump sql "SELECT * FROM EXA_SQL_KEYWORDS WHERE KEYWORD = 'PROFILE'"

# List ALL reserved keywords
exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED ORDER BY KEYWORD"

# Search for keywords matching a pattern
exapump sql "SELECT KEYWORD FROM EXA_SQL_KEYWORDS WHERE RESERVED AND KEYWORD LIKE '%CONNECT%'"
```

When writing DDL or encountering a syntax error on an identifier, always check `EXA_SQL_KEYWORDS` to confirm whether the word is reserved.

> For detailed SQL quirks, see `references/exasol-sql-quirks.md`.

## Remote Data Loading (S3/Azure/GCS)

For loading data from cloud storage, use Exasol's native SQL `IMPORT` statement (exapump only handles local files).

```sql
-- Create a connection object for S3
CREATE OR REPLACE CONNECTION my_s3_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=xxx;S3_SECRET_KEY=yyy';

-- Import CSV from S3
IMPORT INTO my_schema.my_table
FROM CSV AT my_s3_conn
FILE 'path/to/data.csv'
COLUMN SEPARATOR = ','
SKIP = 1;

-- Import Parquet from S3
IMPORT INTO my_schema.my_table
FROM PARQUET AT my_s3_conn
FILE 'path/to/data.parquet';
```

> For Azure/GCS examples and full IMPORT/EXPORT syntax, see `references/exasol-sql-quirks.md`.

## Common Workflows

### Create a new table from a CSV file
```bash
# 1. Preview the schema exapump will infer
exapump upload data.csv --table my_schema.my_table --dry-run --dsn "exasol://..."

# 2. If it looks good, upload
exapump upload data.csv --table my_schema.my_table --dsn "exasol://..."

# 3. Verify
exapump sql "SELECT COUNT(*) FROM my_schema.my_table" --dsn "exasol://..."
```

### Explore data in a table
```bash
# Row count
exapump sql "SELECT COUNT(*) FROM my_schema.my_table"

# Sample rows
exapump sql "SELECT * FROM my_schema.my_table LIMIT 20"

# Column metadata
exapump sql "SELECT * FROM EXA_ALL_COLUMNS WHERE COLUMN_SCHEMA='MY_SCHEMA' AND COLUMN_TABLE='MY_TABLE'"
```

### Export data for analysis
```bash
# Export to CSV for pandas/R
exapump export --query "SELECT * FROM t WHERE date > '2024-01-01'" --output analysis.csv --format csv

# Export to Parquet for Spark/DuckDB
exapump export --table t --output data.parquet --format parquet --compression zstd
```

### Round-trip: upload, transform, export
```bash
# 1. Upload raw data
exapump upload raw.csv --table staging.raw_data

# 2. Transform in SQL
exapump sql "CREATE TABLE prod.clean_data AS SELECT UPPER(name), CAST(amount AS DECIMAL(18,2)) FROM staging.raw_data WHERE amount IS NOT NULL"

# 3. Export results
exapump export --table prod.clean_data --output clean.parquet --format parquet
```
