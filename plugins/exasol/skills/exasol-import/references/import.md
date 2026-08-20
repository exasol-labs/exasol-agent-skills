# Import Workflows

## Decision Guide

Choose the narrowest matching workflow:

- Local CSV or Parquet files on the user's machine: use `exapump upload`; this upload path is for CSV and Parquet only
- Local FBV files on the user's machine: use native `IMPORT INTO "MY_SCHEMA"."MY_TABLE" FROM LOCAL FBV FILE '/path/to/data.fbv'` through an EXAplus or JDBC-style client connection
- Remote CSV or FBV files already reachable by Exasol over FTP/SFTP, HTTP/HTTPS, S3, Azure Blob Storage, or GCS: use native `IMPORT`
- S3 Parquet files: use native `IMPORT INTO "MY_SCHEMA"."MY_TABLE" FROM PARQUET AT s3_conn FILE 'data/file.parquet'`
- Read-only access without copying data: use **exasol-document-virtual-schemas** for a known object or file storage source or **exasol-jdbc-virtual-schemas** for a known database source; use **exasol-extension-catalog** only while choosing the integration family
- An already-selected extension-based object-storage file reader: use **exasol-cloud-storage-extension**

## Connection Objects

Use Exasol connection objects for remote credentials instead of embedding secrets directly in `IMPORT`.

```sql
CREATE OR REPLACE CONNECTION my_conn
TO '<connection-url>'
USER '<username>' IDENTIFIED BY '<password>';
```

Typical patterns:

- S3 long-lived access key and secret key as named values in `IDENTIFIED BY`, with an empty `USER`
- S3 temporary access key and secret key as named values in `IDENTIFIED BY`, with `SESSION TOKEN` for expiring credentials
- Azure account key in `IDENTIFIED BY`
- Azure SAS token in `SAS TOKEN` for Exasol 2026.1 or later
- Azure Microsoft Entra ID in `IDENTIFIED BY`, `CLIENT ID`, and `TENANT ID` for Exasol 2026.1 or later
- GCS access key and secret key in `IDENTIFIED BY`
- Prefer `ALTER CONNECTION` when a credential changes and existing grants should stay intact

Examples:

```sql
CREATE OR REPLACE CONNECTION s3_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=<access-key>;S3_SECRET_KEY=<secret-key>';

CREATE OR REPLACE CONNECTION s3_temp_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=<temporary-access-key>;S3_SECRET_KEY=<temporary-secret-key>'
SESSION TOKEN '<session-token>';

CREATE OR REPLACE CONNECTION azure_key_conn
TO 'DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net'
USER '<account-name>' IDENTIFIED BY '<account-key>';

CREATE OR REPLACE CONNECTION azure_sas_conn
TO 'DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net'
USER '<account-name>' SAS TOKEN '<sas-token>';

CREATE OR REPLACE CONNECTION azure_entra_conn
TO 'DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net'
USER '<account-name>' IDENTIFIED BY '<client-secret>'
CLIENT ID '<client-id>'
TENANT ID '<tenant-id>';

CREATE OR REPLACE CONNECTION gcs_conn
TO 'https://storage.googleapis.com/my-bucket'
USER '' IDENTIFIED BY 'GCS_ACCESS_KEY=<access-key>;GCS_SECRET_KEY=<secret-key>';
```

Use `SESSION TOKEN` when the source relies on short-lived AWS credentials.
When the token or secret changes, refresh the existing object with
`ALTER CONNECTION` before running the next load:

```sql
ALTER CONNECTION s3_temp_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=<temporary-access-key>;S3_SECRET_KEY=<temporary-secret-key>'
SESSION TOKEN '<session-token>';
```

For Azure Blob import sources, use the Azure connection object with
`AT CLOUD AZURE BLOBSTORAGE <connection>` and a file path in
`'<container>/<blob>'` form.

## Security and Boundaries

- Use connection objects instead of placing secrets in ad hoc local files
- Do not paste real customer credentials into prompts, checked-in SQL files, or shell history examples
- Keep the connection object scoped to the workflow instead of reusing over-privileged credentials by default
- Do not suggest bypassing normal database privileges or connection-object controls
- Use sample placeholders in examples, not real keys, tokens, bucket names, or customer data

## Native IMPORT

Supported native paths covered here:

- CSV from LOCAL, FTP/SFTP, HTTP/HTTPS, S3, Azure, and GCS
- FBV from LOCAL, FTP/SFTP, HTTP/HTTPS, S3, Azure, and GCS
- Parquet from S3

`FROM LOCAL <FORMAT> FILE '<path>'` works only through EXAplus or JDBC-style client connections, not from UDF scripts or Lua scripts. For local CSV or Parquet files on the user's machine, prefer `exapump upload` instead of asking the user to manage JDBC-local paths manually.

### CSV Example

```sql
IMPORT INTO "MY_SCHEMA"."MY_TABLE"
FROM CSV AT s3_conn
FILE 'data/orders.csv'
COLUMN SEPARATOR = ','
SKIP = 1
REJECT LIMIT 0;
```

### Parquet Example

```sql
IMPORT INTO "MY_SCHEMA"."MY_TABLE"
FROM PARQUET AT s3_conn
FILE 'data/*.parquet';
```

Important Parquet behavior:

- native Parquet import is an S3 workflow
- use `SOURCE COLUMN NAMES` when column-name mapping is safer than positional mapping
- use `SkipCols` in the `FILE` clause when the source contains leading columns you want to skip
- use `MaxConnections` and `MaxConcurrentReads` in the `FILE` clause to tune large parallel loads

## Local File Workflows With exapump

Use `exapump upload` for local CSV or Parquet files when the file lives on the user's machine and the user wants a terminal workflow.

Typical pattern:

- `exapump upload <file> --table <schema.table>`
- With a non-default profile: `exapump upload --profile <name> <file> --table <schema.table>`

Use `exapump upload <file> --table <schema.table> --dry-run` first when the user wants to preview inferred schema or mappings before the actual load. With a non-default profile, keep `--profile <name>` after `upload`.

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
FROM CSV AT s3_conn
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

- If the user needs the Cloud Storage Extension rather than direct `IMPORT`, switch to **exasol-cloud-storage-extension**
- If the user wants to write data out of Exasol, switch to **exasol-export** for native `EXPORT` or local export workflows
- If the user wants federated read-only access instead of copying data, use **exasol-document-virtual-schemas** for a known object or file storage source or **exasol-jdbc-virtual-schemas** for a known database source. Use **exasol-extension-catalog** only when the source or integration family is still undecided.
