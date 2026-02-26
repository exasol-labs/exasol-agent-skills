# exapump CLI Reference

> Single-binary CLI for CSV/Parquet ingest and SQL execution against Exasol.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh
```

## Global Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Print help |
| `-V, --version` | Print version |
| `--profile <NAME>` | Use a saved connection profile instead of the default |

## Connection Profiles

exapump uses saved connection profiles. The default profile is used automatically; use `--profile <name>` to select a different one.

```bash
# Add a new profile (interactive — prompts for host, port, user, password, TLS)
exapump profile add default

# List saved profiles
exapump profile list
```

---

## upload

Upload local CSV or Parquet files to an Exasol table. Auto-creates the table if it doesn't exist.

```
exapump upload [OPTIONS] --table <TABLE> <FILES>...
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<FILES>...` | Yes | One or more files to upload (CSV or Parquet) |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-t, --table <TABLE>` | (required) | Target table name (e.g., `schema.table`) |
| `--dry-run` | off | Preview inferred schema without loading data |
| `--delimiter <CHAR>` | `,` | CSV field delimiter |
| `--no-header` | off | Treat the first row as data, not a header |
| `--quote <CHAR>` | `"` | CSV quoting character |
| `--escape <CHAR>` | (none) | CSV escape character |
| `--null-value <STR>` | `""` (empty string) | String to interpret as NULL |

### Example

```bash
exapump upload data.csv --table my_schema.my_table --dry-run
```

---

## sql

Execute SQL statements against Exasol. Returns results in CSV or JSON format for SELECT queries.

```
exapump sql [OPTIONS] [SQL]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `[SQL]` | No | SQL statement to execute. Reads from stdin if omitted or if `-` is given. |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-f, --format <FORMAT>` | `csv` | Output format for SELECT results. Values: `csv`, `json` |

### Example

```bash
exapump sql "SELECT * FROM my_table LIMIT 10"
```

---

## export

Export an Exasol table or query result to a local file. Supports CSV and Parquet output with optional file splitting.

```
exapump export [OPTIONS] --output <OUTPUT> --format <FORMAT>
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

### Example

```bash
exapump export --table my_schema.my_table --output data.parquet --format parquet --compression zstd
```

---

## interactive

Start an interactive SQL REPL session connected to Exasol.

```
exapump interactive
```

### Example

```bash
exapump interactive --profile production
```
