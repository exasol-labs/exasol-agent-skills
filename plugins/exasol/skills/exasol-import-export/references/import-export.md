# Import and Export Workflows

## Decision Guide

Choose the narrowest matching workflow:

- Local CSV or Parquet files on the user's machine: use `exapump upload` or `exapump export`
- Remote CSV or FBV files reachable by Exasol: use native `IMPORT` or `EXPORT`
- S3 Parquet files: use native `IMPORT ... FROM PARQUET AT <connection>`
- Read-only access to external systems without copying data: use **exasol-virtual-schemas**
- Extension-based file readers or streaming loaders: use **exasol-data-loading**

## Connection Objects

Use Exasol connection objects for remote credentials instead of embedding secrets directly in `IMPORT` or `EXPORT`.

```sql
CREATE OR REPLACE CONNECTION my_conn
TO 'connection-url'
USER 'username' IDENTIFIED BY 'password';
```

Typical patterns:

- S3 long-lived access key in `USER` and secret key in `IDENTIFIED BY`
- S3 temporary access key in `USER`, secret key in `IDENTIFIED BY`, and `SESSION TOKEN` for expiring credentials
- Azure SAS token in `IDENTIFIED BY`
- GCS access key and secret key in `IDENTIFIED BY`
- Prefer `ALTER CONNECTION` when a credential changes and existing grants should stay intact

Examples:

```sql
CREATE OR REPLACE CONNECTION s3_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER 'AKIA...'
IDENTIFIED BY 'secret...';

CREATE OR REPLACE CONNECTION s3_temp_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER 'ASIA...'
IDENTIFIED BY 'secret...'
SESSION TOKEN 'FwoGZXIvYXdz...';

CREATE OR REPLACE CONNECTION azure_conn
TO 'https://myaccount.blob.core.windows.net/mycontainer'
USER '' IDENTIFIED BY 'AZURE_SAS_TOKEN=...';

CREATE OR REPLACE CONNECTION gcs_conn
TO 'https://storage.googleapis.com/my-bucket'
USER '' IDENTIFIED BY 'GCS_ACCESS_KEY=...;GCS_SECRET_KEY=...';
```

Use `SESSION TOKEN` when the source relies on short-lived AWS credentials.
When the token or secret changes, refresh the existing object with
`ALTER CONNECTION` before running the next load:

```sql
ALTER CONNECTION s3_temp_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER 'ASIA...'
IDENTIFIED BY 'new_secret...'
SESSION TOKEN 'new_token...';
```

## Security and Boundaries

- use connection objects instead of placing secrets in ad hoc local files
- do not paste real customer credentials into prompts, checked-in SQL files, or shell history examples
- keep the connection object scoped to the workflow instead of reusing over-privileged credentials by default
- do not suggest bypassing normal database privileges or connection-object controls
- use sample placeholders in examples, not real keys, tokens, bucket names, or customer data

## Native IMPORT

Supported native paths covered here:

- CSV from LOCAL, FTP/SFTP, HTTP/HTTPS, S3, Azure, and GCS
- FBV from LOCAL, FTP/SFTP, HTTP/HTTPS, S3, Azure, and GCS
- Parquet from S3

`FROM LOCAL` works through JDBC-style client connections. For local files on the user's machine, prefer `exapump upload` instead of asking the user to manage JDBC-local paths manually.

### CSV Example

```sql
IMPORT INTO my_schema.my_table
FROM CSV AT s3_conn
FILE 'data/orders.csv'
COLUMN SEPARATOR = ','
SKIP = 1
REJECT LIMIT 0;
```

### Parquet Example

```sql
IMPORT INTO my_schema.my_table
FROM PARQUET AT s3_conn
FILE 'data/*.parquet';
```

Important Parquet behavior:

- native Parquet import is an S3 workflow
- use `SOURCE COLUMN NAMES` when column-name mapping is safer than positional mapping
- use `SkipCols` in the `FILE` clause when the source contains leading columns you want to skip
- use `MaxConnections` and `MaxConcurrentReads` in the `FILE` clause to tune large parallel loads

## Native EXPORT

Use native `EXPORT` when Exasol should write the result to a remote target or to a local JDBC-style target.

```sql
EXPORT my_schema.my_table
INTO CSV AT s3_conn
FILE 'exports/orders.csv'
WITH COLUMN NAMES;
```

For local exports on the user's machine, `exapump export` is usually the simpler path.

## Local File Workflows With exapump

Use `exapump` when the file lives on the user's machine and the user wants a terminal workflow.

Typical patterns:

- `exapump upload <file> --table <schema.table>`
- `exapump export <schema.table> --output <file>`

Use `exapump upload --dry-run` first when the user wants to preview inferred schema or mappings before the actual load.

## Error Handling

Useful native controls:

- `REJECT LIMIT 0` to fail on the first bad row
- `REJECT LIMIT n` to allow a bounded number of row-level parse errors
- `ERRORS INTO <table>` to capture rejected rows for inspection

Constraint violations are not a row-rejection case. They fail the import immediately.

## Staging Pattern

When the target table is business-critical, prefer staging first and merge later:

```sql
CREATE TABLE staging.orders_stg (LIKE production.orders INCLUDING DEFAULTS);

IMPORT INTO staging.orders_stg
FROM CSV AT s3_conn
FILE 'daily/orders_*.csv'
COLUMN SEPARATOR = ','
SKIP = 1
REJECT LIMIT 100;

MERGE INTO production.orders t
USING staging.orders_stg s ON (t.order_id = s.order_id)
WHEN MATCHED THEN UPDATE SET
    t.status = s.status,
    t.amount = s.amount
WHEN NOT MATCHED THEN INSERT VALUES (
    s.order_id, s.customer_id, s.status, s.amount
);
```

## Adjacent Routing

- If the user needs a connector, extension, or migration framework rather than direct IMPORT/EXPORT, switch to **exasol-data-loading**
- If the user wants federated read-only access instead of copying data, switch to **exasol-virtual-schemas**
