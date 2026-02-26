# Data Loading & Export

## When to Use What

| Scenario | Tool | Reference |
|----------|------|-----------|
| Local files (CSV/Parquet on your machine) | **exapump CLI** (`upload` / `export`) | `exapump-reference.md` |
| Remote / cloud files (S3, Azure, GCS, FTP, HTTP) | **SQL IMPORT / EXPORT** (EXALoader bulk load) | This file |
| Read-only access to external databases | **Virtual Schemas** | `virtual-schemas.md` |

Use `IMPORT`/`EXPORT` when the data source or destination is a remote location accessible from the Exasol cluster. Use exapump when files are on your local machine (exapump tunnels data through a local JDBC connection). Virtual Schemas are for federated queries against external databases without copying data.

---

## Connection Objects

Connection objects store credentials for remote data sources. Required for cloud IMPORT/EXPORT.

```sql
-- Create
CREATE OR REPLACE CONNECTION my_conn
TO 'connection-url'
USER 'username' IDENTIFIED BY 'password';

-- View all connections (DBA only)
SELECT * FROM EXA_DBA_CONNECTIONS;

-- Drop
DROP CONNECTION my_conn;
```

### Cloud Connection Strings

**S3:**
```sql
CREATE OR REPLACE CONNECTION s3_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=AKIA...;S3_SECRET_KEY=secret...';
```

**Azure Blob Storage:**
```sql
CREATE OR REPLACE CONNECTION azure_conn
TO 'https://myaccount.blob.core.windows.net/mycontainer'
USER '' IDENTIFIED BY 'AZURE_SAS_TOKEN=sv=2021-06-08&ss=b&srt=co...';
```

**Google Cloud Storage:**
```sql
CREATE OR REPLACE CONNECTION gcs_conn
TO 'https://storage.googleapis.com/my-bucket'
USER '' IDENTIFIED BY 'GCS_ACCESS_KEY=GOOG...;GCS_SECRET_KEY=secret...';
```

### TLS Certificate Verification

Add to connection string to control TLS behavior:
```sql
-- Disable certificate verification (not recommended for production)
CREATE OR REPLACE CONNECTION my_conn
TO 'https://...'
USER '' IDENTIFIED BY '...;VERIFY=FALSE';
```

---

## IMPORT Statement

### Supported Formats

| Format | Sources | Notes |
|--------|---------|-------|
| **CSV** | LOCAL, FTP/SFTP, HTTP/HTTPS, S3, Azure, GCS | Most flexible format |
| **FBV** (Fixed-width) | LOCAL, FTP/SFTP, HTTP/HTTPS, S3, Azure, GCS | Uses SIZE, ALIGN, PADDING per column |
| **Parquet** | **S3 only** | Type mappings apply; column mapping via SOURCE COLUMN NAMES |

### LOCAL Restriction

`FROM LOCAL CSV FILE` only works from **EXAplus or JDBC connections**. It does **not** work from within UDF scripts or Lua scripts. For local files, prefer exapump CLI which handles the JDBC tunneling automatically.

### CSV Options

| Option | Default | Description |
|--------|---------|-------------|
| `COLUMN SEPARATOR` | `,` | Field delimiter character |
| `COLUMN DELIMITER` | `"` (none for FBV) | Text qualifier / quoting character |
| `ROW SEPARATOR` | `LF` | `LF`, `CR`, `CRLF`, or a custom string |
| `SKIP = n` | 0 | Skip first n rows (header lines) |
| `TRIM` | — | `TRIM`, `LTRIM`, or `RTRIM` to strip whitespace from fields |
| `ENCODING` | `UTF-8` | Character encoding of source file |
| `NULL = 'str'` | — | String that represents NULL values |

### IMPORT FROM Local CSV

```sql
IMPORT INTO my_schema.my_table
FROM LOCAL CSV FILE '/path/to/data.csv'
COLUMN SEPARATOR = ','
COLUMN DELIMITER = '"'
SKIP = 1
REJECT LIMIT 0;
```

### IMPORT FROM S3 (CSV)

```sql
IMPORT INTO my_schema.my_table
FROM CSV AT s3_conn
FILE 'path/to/data.csv'
COLUMN SEPARATOR = ','
SKIP = 1;
```

### IMPORT FROM S3 (Parquet)

```sql
IMPORT INTO my_schema.my_table
FROM PARQUET AT s3_conn
FILE 'data/*.parquet';  -- wildcards supported
```

**Parquet type mappings:** INT32/INT64 → DECIMAL, FLOAT/DOUBLE → DOUBLE PRECISION, BYTE_ARRAY → VARCHAR, BOOLEAN → BOOLEAN, INT96 → TIMESTAMP.

**Column mapping:** Use `SOURCE COLUMN NAMES` to map Parquet columns to table columns by name rather than position. Use `(... SkipCols=n ...)` in the FILE clause to skip leading columns.

**Parallel config:** Control parallelism with `(... MaxConnections=n MaxConcurrentReads=n ...)` in the FILE clause for large Parquet imports.

### IMPORT FROM Azure Blob Storage

```sql
IMPORT INTO my_schema.my_table
FROM CSV AT azure_conn
FILE 'data/file.csv';
```

### IMPORT FROM Google Cloud Storage

```sql
IMPORT INTO my_schema.my_table
FROM CSV AT gcs_conn
FILE 'data/file.csv';
```

### Compressed Files

Exasol automatically detects and decompresses `.zip`, `.gz`, and `.bz2` files during IMPORT. No special syntax needed — just reference the compressed file:

```sql
IMPORT INTO my_table FROM CSV AT s3_conn FILE 'data/archive.csv.gz';
```

### Wildcards and Multiple Files

```sql
-- Wildcard: load all matching files in parallel
IMPORT INTO my_table FROM CSV AT s3_conn FILE 'data/2024/*.csv';

-- Multiple FILE clauses: load from several paths in parallel
IMPORT INTO my_table FROM CSV AT s3_conn
FILE 'data/region_a/orders.csv'
FILE 'data/region_b/orders.csv'
FILE 'data/region_c/orders.csv';
```

---

## Error Handling

### REJECT LIMIT

Controls how many rows can be rejected before the IMPORT fails:

```sql
-- Fail on first bad row
IMPORT INTO my_table FROM CSV AT conn FILE 'data.csv' REJECT LIMIT 0;

-- Allow up to 100 rejected rows
IMPORT INTO my_table FROM CSV AT conn FILE 'data.csv' REJECT LIMIT 100;

-- Never fail due to bad rows
IMPORT INTO my_table FROM CSV AT conn FILE 'data.csv' REJECT LIMIT UNLIMITED;
```

### ERRORS INTO Table

Capture rejected rows in an error table for inspection:

```sql
IMPORT INTO my_table FROM CSV AT conn FILE 'data.csv'
REJECT LIMIT 100
ERRORS INTO error_schema.import_errors;
```

The error table contains columns for: row number, error message, and the raw data of the rejected row.

### ERRORS INTO CSV File

Write rejected rows to a CSV file instead:

```sql
IMPORT INTO my_table FROM CSV AT conn FILE 'data.csv'
REJECT LIMIT 100
ERRORS INTO CSV FILE '/path/to/errors.csv';
```

### Constraint Violations

Constraint violations (e.g. NOT NULL, PRIMARY KEY) always cause the IMPORT to fail immediately — they are **not** subject to REJECT LIMIT.

---

## EXPORT Statement

### EXPORT to Local CSV

```sql
EXPORT my_schema.my_table
INTO LOCAL CSV FILE '/path/to/output.csv'
COLUMN SEPARATOR = ','
COLUMN DELIMITER = '"'
WITH COLUMN NAMES;
```

### EXPORT Query Result

```sql
EXPORT (SELECT * FROM t WHERE status = 'active')
INTO LOCAL CSV FILE '/path/to/active.csv'
WITH COLUMN NAMES;
```

**Note:** `ORDER BY` is only honored at the top level of the exported query. Subqueries with ORDER BY may not preserve order in the output.

### EXPORT to Cloud Storage

```sql
-- S3
EXPORT my_schema.my_table INTO CSV AT s3_conn FILE 'exports/data.csv' WITH COLUMN NAMES;

-- Azure
EXPORT my_schema.my_table INTO CSV AT azure_conn FILE 'exports/data.csv' WITH COLUMN NAMES;

-- GCS
EXPORT my_schema.my_table INTO CSV AT gcs_conn FILE 'exports/data.csv' WITH COLUMN NAMES;
```

### CSV Export Options

Same options as IMPORT, plus:

| Option | Description |
|--------|-------------|
| `WITH COLUMN NAMES` | Write header row with column names |
| `DELIMIT = ALWAYS \| NEVER \| AUTO` | When to quote fields (default: AUTO) |
| `BOOLEAN = 'true/false'` | Custom boolean representation |

### AWS Server-Side Encryption (SSE)

```sql
-- AES256 encryption
EXPORT my_table INTO CSV AT s3_conn FILE 'data.csv'
WITH COLUMN NAMES
(... SSE='AES256' ...);

-- KMS encryption
EXPORT my_table INTO CSV AT s3_conn FILE 'data.csv'
WITH COLUMN NAMES
(... SSE='aws:kms' SSEKmsKeyId='key-id' ...);
```

---

## Staging Workflow

A common ETL pattern: load into a staging table, merge into production, then clean up.

```sql
-- 1. Create a staging table matching the target structure
CREATE TABLE staging.orders_stg (LIKE production.orders INCLUDING DEFAULTS);

-- 2. Import into staging (with error handling)
IMPORT INTO staging.orders_stg
FROM CSV AT s3_conn FILE 'daily/orders_*.csv'
COLUMN SEPARATOR = ','
SKIP = 1
REJECT LIMIT 100;

-- 3. Merge staging into production (upsert)
MERGE INTO production.orders t
USING staging.orders_stg s ON (t.order_id = s.order_id)
WHEN MATCHED THEN UPDATE SET
    t.status = s.status,
    t.amount = s.amount,
    t.updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN INSERT VALUES (
    s.order_id, s.customer_id, s.status, s.amount, CURRENT_TIMESTAMP
);

-- 4. Clean up staging
TRUNCATE TABLE staging.orders_stg;
COMMIT;
```
