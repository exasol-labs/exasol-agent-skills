# Export Workflows

## Decision Guide

Choose the narrowest matching workflow:

- Local CSV or Parquet files on the user's machine: use `exapump export`
- Remote CSV or FBV file targets reachable by Exasol through supported targets such as S3, Azure Blob Storage, GCS, FTP/SFTP, or HTTP/HTTPS: use native `EXPORT`
- Database or JDBC destinations reachable by Exasol: use native `EXPORT`
- For the matching data-movement-into-Exasol workflow, use **exasol-import** for native `IMPORT`, local upload workflows, Parquet import, reject handling, and staging-based loading.

## Connection Objects

Use Exasol connection objects for remote credentials instead of embedding secrets directly in `EXPORT`.

```sql
CREATE OR REPLACE CONNECTION my_conn
TO '<connection-url>'
USER '<username>' IDENTIFIED BY '<password>';
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
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=<access-key>;S3_SECRET_KEY=<secret-key>';

CREATE OR REPLACE CONNECTION s3_temp_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=<temporary-access-key>;S3_SECRET_KEY=<secret-key>'
SESSION TOKEN '<session-token>';

CREATE OR REPLACE CONNECTION azure_conn
TO 'https://myaccount.blob.core.windows.net/mycontainer'
USER '' IDENTIFIED BY 'AZURE_SAS_TOKEN=<sas-token>';

CREATE OR REPLACE CONNECTION gcs_conn
TO 'https://storage.googleapis.com/my-bucket'
USER '' IDENTIFIED BY 'GCS_ACCESS_KEY=<access-key>;GCS_SECRET_KEY=<secret-key>';
```

Use `SESSION TOKEN` when the target relies on short-lived AWS credentials.
When the token or secret changes, refresh the existing object with
`ALTER CONNECTION` before running the next export:

```sql
ALTER CONNECTION s3_temp_conn
TO 'https://my-bucket.s3.eu-west-1.amazonaws.com'
USER '' IDENTIFIED BY 'S3_ACCESS_KEY=<temporary-access-key>;S3_SECRET_KEY=<secret-key>'
SESSION TOKEN '<session-token>';
```

## Security and Boundaries

- Use connection objects instead of placing secrets in ad hoc local files
- Do not paste real customer credentials into prompts, checked-in SQL files, or shell history examples
- Keep the connection object scoped to the workflow instead of reusing over-privileged credentials by default
- Do not suggest bypassing normal database privileges or connection-object controls
- Use sample placeholders in examples, not real keys, tokens, bucket names, or customer data

## Native EXPORT

Use native `EXPORT` when Exasol should write the result to a remote file target, database/JDBC destination, or JDBC/EXAplus-style local target.
For file exports, native `EXPORT` covers CSV and FBV. For local Parquet files on the user's machine, use `exapump export`.

```sql
EXPORT "MY_SCHEMA"."MY_TABLE"
INTO CSV AT s3_conn
FILE 'exports/orders.csv'
WITH COLUMN NAMES;
```

For JDBC/EXAplus local files, the native form is `INTO LOCAL <CSV|FBV> FILE '<path>'`.
For terminal local exports on the user's machine, `exapump export` is usually the simpler path.

```sql
EXPORT "MY_SCHEMA"."MY_TABLE"
INTO LOCAL CSV FILE '/path/to/orders.csv'
WITH COLUMN NAMES;
```

## Local File Workflows With exapump

Use `exapump export` when the file lives on the user's machine and the user wants a terminal workflow.

Typical pattern:

- `exapump export --table <schema.table> --output <file> --format <csv|parquet>`
- `exapump export --query "SELECT * FROM <schema.table>" --output <file> --format <csv|parquet>`
- With a non-default profile: `exapump export --profile <name> --table <schema.table> --output <file> --format <csv|parquet>`
- For Parquet compression, add `--compression <snappy|gzip|lz4|zstd|none>`
- For split output files, add `--max-rows-per-file <n>` or `--max-file-size <size>`

## Script-Based EXPORT

Use native `EXPORT ... INTO SCRIPT` only when the user explicitly asks for a script target.
Keep this skill focused on the export statement and route script implementation details to **exasol-udfs**.
Add `WITH <property> = <value>` only when the target script expects properties.

```sql
EXPORT "MY_SCHEMA"."MY_TABLE"
INTO SCRIPT "MY_SCHEMA"."MY_EXPORT_SCRIPT";
```

## Adjacent Routing

- If the user wants to load data into Exasol instead of writing it out, switch to **exasol-import** for native `IMPORT`, local upload workflows, Parquet import, reject handling, and staging-based loading.
- If the user asks for connector, extension, or integration-based data transfer instead of direct native `EXPORT` or `exapump export`, switch to **exasol-extension-catalog**.
- If the user needs to create or change the script used by `EXPORT ... INTO SCRIPT`, switch to **exasol-udfs** for script implementation details.
