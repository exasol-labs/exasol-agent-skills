# Import Workflows

## Decision Guide

Choose the narrowest matching workflow:

- Local CSV or Parquet files on the user's machine: use `exapump upload`
- Remote CSV or FBV files already reachable by Exasol over FTP/SFTP, HTTP/HTTPS, S3, Azure Blob Storage, or GCS: use native `IMPORT`
- S3 Parquet files: use native `IMPORT INTO <table> FROM PARQUET AT <connection> FILE <path>`
- Read-only access to external systems without copying data: use **exasol-extension-catalog** to choose the right Virtual Schema path
- Extension-based object-storage file readers: use **exasol-extension-catalog** to route to the Cloud Storage Extension material

## Connection Objects

Use Exasol connection objects for remote credentials instead of embedding secrets directly in `IMPORT`.

```sql
CREATE OR REPLACE CONNECTION my_conn
TO 'connection-url'
USER 'username' IDENTIFIED BY 'password';
```

Typical patterns:

- S3 long-lived access key and secret key as named values in `IDENTIFIED BY`, with an empty `USER`
- S3 temporary access key and secret key as named values in `IDENTIFIED BY`, with `SESSION TOKEN` for expiring credentials
- Azure SAS token in `IDENTIFIED BY`
- GCS access key and secret key in `IDENTIFIED BY`
- Prefer `ALTER CONNECTION` when a credential changes and existing grants should stay intact

Examples:

```sql
CREATE OR REPLACE CONNECTION s3_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=AKIA...;S3_SECRET_KEY=secret...';

CREATE OR REPLACE CONNECTION s3_temp_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=ASIA...;S3_SECRET_KEY=secret...'
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
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=ASIA...;S3_SECRET_KEY=new_secret...'
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
IMPORT INTO "MY_SCHEMA"."MY_TABLE"
FROM CSV AT "S3_CONN"
FILE 'data/orders.csv'
COLUMN SEPARATOR = ','
SKIP = 1
REJECT LIMIT 0;
```

### Parquet Example

```sql
IMPORT INTO "MY_SCHEMA"."MY_TABLE"
FROM PARQUET AT "S3_CONN"
FILE 'data/*.parquet';
```

Important Parquet behavior:

- native Parquet import is an S3 workflow
- use `SOURCE COLUMN NAMES` when column-name mapping is safer than positional mapping
- use `SkipCols` in the `FILE` clause when the source contains leading columns you want to skip
- use `MaxConnections` and `MaxConcurrentReads` in the `FILE` clause to tune large parallel loads

## Local File Workflows With exapump

Use `exapump` when the file lives on the user's machine and the user wants a terminal workflow.

Typical pattern:

- `exapump upload <file> --table <schema.table>`

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
CREATE TABLE "STAGING"."ORDERS_STG" (LIKE "PRODUCTION"."ORDERS" INCLUDING DEFAULTS);

IMPORT INTO "STAGING"."ORDERS_STG"
FROM CSV AT "S3_CONN"
FILE 'daily/orders_*.csv'
COLUMN SEPARATOR = ','
SKIP = 1
REJECT LIMIT 100;

MERGE INTO "PRODUCTION"."ORDERS" t
USING "STAGING"."ORDERS_STG" s ON (t."ORDER_ID" = s."ORDER_ID")
WHEN MATCHED THEN UPDATE SET
    t."STATUS" = s."STATUS",
    t."AMOUNT" = s."AMOUNT"
WHEN NOT MATCHED THEN INSERT VALUES (
    s."ORDER_ID", s."CUSTOMER_ID", s."STATUS", s."AMOUNT"
);
```

## Adjacent Routing

- If the user needs an extension-based object-storage loading workflow rather than direct `IMPORT`, switch to **exasol-extension-catalog**
- If the user wants to write data out of Exasol, switch to **exasol-database** for native `EXPORT`
- If the user wants federated read-only access instead of copying data, switch to **exasol-extension-catalog**
