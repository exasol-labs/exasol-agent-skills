# exapump CLI Reference

> The simplest path from file to Exasol table — a single-binary CLI for CSV and Parquet ingest.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh
```

## Global Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Print help |
| `-V, --version` | Print version |

## Connection String (DSN)

All commands require a DSN. Format:

```
exasol://user:password@host:port[?param=value&...]
```

### DSN Query Parameters

| Parameter | Values | Default | Description |
|-----------|--------|---------|-------------|
| `tls` | `true`/`false` | `false` | Enable TLS encryption |
| `validate_certificate` | `true`/`false` | `true` | Validate server TLS certificate |
| `timeout` | seconds | `30` | Connection timeout |
| `query_timeout` | seconds | `300` | Query execution timeout |
| `idle_timeout` | seconds | `600` | Idle connection timeout |
| `client_name` | string | `exarrow-rs` | Client name for session identification |

### Docker / Self-Signed Certificate Setup

Exasol Docker containers use self-signed certificates. You must enable TLS and disable certificate validation:

```
exasol://sys:exasol@localhost:8563?tls=true&validate_certificate=false
```

Without `tls=true`, you get: `Only TLS connections are allowed`.
Without `validate_certificate=false`, you get: `invalid peer certificate`.

The DSN can be provided via:
- `--dsn` flag on every command
- `EXAPUMP_DSN` environment variable
- `.env` file in the current directory

---

## upload

Upload local CSV or Parquet files to an Exasol table. Auto-creates the table if it doesn't exist.

```
exapump upload [OPTIONS] --table <TABLE> --dsn <DSN> <FILES>...
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<FILES>...` | Yes | One or more files to upload (CSV or Parquet) |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-t, --table <TABLE>` | (required) | Target table name (e.g., `schema.table`) |
| `-d, --dsn <DSN>` | `$EXAPUMP_DSN` | Connection string |
| `--dry-run` | off | Preview inferred schema without loading data |
| `--delimiter <CHAR>` | `,` | CSV field delimiter |
| `--no-header` | off | Treat the first row as data, not a header |
| `--quote <CHAR>` | `"` | CSV quoting character |
| `--escape <CHAR>` | (none) | CSV escape character |
| `--null-value <STR>` | `""` (empty string) | String to interpret as NULL |

### Examples

```bash
# Basic CSV upload
exapump upload data.csv --table my_schema.my_table

# Dry run to preview schema
exapump upload data.csv --table my_schema.my_table --dry-run

# Multiple files
exapump upload part1.csv part2.csv part3.csv --table my_schema.combined

# Tab-separated (file must have .csv extension)
exapump upload data.csv --table my_schema.my_table --delimiter $'\t'

# Pipe-separated, no header (file must have .csv extension)
exapump upload data.csv --table my_schema.my_table --delimiter '|' --no-header

# Custom NULL representation
exapump upload data.csv --table my_schema.my_table --null-value "N/A"

# Parquet file
exapump upload data.parquet --table my_schema.my_table
```

---

## sql

Execute SQL statements against Exasol. Returns results in CSV or JSON format for SELECT queries.

```
exapump sql [OPTIONS] --dsn <DSN> [SQL]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `[SQL]` | No | SQL statement to execute. Reads from stdin if omitted or if `-` is given. |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-d, --dsn <DSN>` | `$EXAPUMP_DSN` | Connection string |
| `-f, --format <FORMAT>` | `csv` | Output format for SELECT results. Values: `csv`, `json` |

### Examples

```bash
# Simple query
exapump sql "SELECT * FROM my_table LIMIT 10"

# JSON output
exapump sql "SELECT * FROM my_table" --format json

# DDL statement
exapump sql "CREATE SCHEMA IF NOT EXISTS analytics"

# DML statement
exapump sql "INSERT INTO t VALUES (1, 'hello')"

# From stdin
echo "SELECT CURRENT_DATE" | exapump sql

# From file
exapump sql < migration.sql
```

---

## export

Export an Exasol table or query result to a local file. Supports CSV and Parquet output with optional file splitting.

```
exapump export [OPTIONS] --output <OUTPUT> --format <FORMAT> --dsn <DSN>
```

### Source (one required)

| Option | Description |
|--------|-------------|
| `-t, --table <TABLE>` | Table to export (e.g., `schema.table`) |
| `-q, --query <QUERY>` | SQL query to export results from |

### Output Options

| Option | Default | Description |
|--------|---------|-------------|
| `-o, --output <OUTPUT>` | (required) | Output file path |
| `-f, --format <FORMAT>` | (required) | Export format: `csv`, `parquet` |
| `-d, --dsn <DSN>` | `$EXAPUMP_DSN` | Connection string |

### CSV Options

| Option | Default | Description |
|--------|---------|-------------|
| `--delimiter <CHAR>` | `,` | CSV field delimiter |
| `--quote <CHAR>` | `"` | CSV quoting character |
| `--no-header` | off | Exclude header row from output |
| `--null-value <STR>` | `""` (empty string) | String to represent NULL values |

### Parquet Options

| Option | Default | Description |
|--------|---------|-------------|
| `--compression <CODEC>` | (none) | Compression codec: `snappy`, `gzip`, `lz4`, `zstd`, `none` |

### File Splitting Options

| Option | Description |
|--------|-------------|
| `--max-rows-per-file <N>` | Maximum rows per output file |
| `--max-file-size <SIZE>` | Maximum file size per output file (e.g., `500KB`, `1MB`, `2GB`) |

When splitting is enabled, output files are numbered automatically (e.g., `data_000.csv`, `data_001.csv`).

### Examples

```bash
# Export table to CSV
exapump export --table my_schema.my_table --output data.csv --format csv

# Export query result to Parquet with compression
exapump export --query "SELECT col_a, col_b FROM t" \
  --output result.parquet --format parquet --compression zstd

# Export without header
exapump export --table t --output data.csv --format csv --no-header

# Split large export by row count
exapump export --table t --output chunks.csv --format csv --max-rows-per-file 1000000

# Split by file size
exapump export --table t --output chunks.parquet --format parquet --max-file-size 500MB

# Custom delimiter and NULL representation
exapump export --table t --output data.csv --format csv --delimiter $'\t' --null-value "NULL"
```

---

## interactive

Start an interactive SQL REPL session connected to Exasol.

```
exapump interactive --dsn <DSN>
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-d, --dsn <DSN>` | `$EXAPUMP_DSN` | Connection string |

### Example

```bash
exapump interactive --dsn "exasol://sys:exasol@localhost:8563"
```
