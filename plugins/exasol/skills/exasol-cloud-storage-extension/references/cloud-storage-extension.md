# Cloud Storage Extension Workflows

## Decision Guide

Pick the narrowest supported transfer path:

- Direct local CSV or Parquet upload into Exasol: use **exasol-import**
- Direct local CSV or Parquet export from Exasol: use **exasol-export**
- Direct native `IMPORT` SQL: use **exasol-import**
- Direct native `EXPORT` SQL or local `exapump export`: use **exasol-export**
- Cloud Storage Extension import from object storage: use this skill for Parquet, Avro, ORC, or supported Delta workflows
- Cloud Storage Extension export to object storage: use this skill for Parquet export workflows
- CSV files: use native `IMPORT`, native `EXPORT`, or `exapump`; Cloud Storage Extension does not support CSV
- Read-only federation instead of copying data: use **exasol-extension-catalog** to choose the right Virtual Schema path

## Security and Boundaries

- Prefer Exasol connection objects for cloud credentials so secrets are not written directly into `IMPORT` or `EXPORT` statements
- The database user running the Cloud Storage Extension `IMPORT` or `EXPORT` statement needs `ACCESS` on the referenced connection object, either directly or through a role
- Do not move secrets into ad hoc local artifacts just to make the agent workflow easier
- Do not suggest bypassing normal source-system permissions, connection boundaries, or Exasol privileges
- Use placeholders in examples instead of real customer endpoints, keys, tokens, or datasets
- Keep the distinction clear between database-side SQL, external source systems, and supporting infrastructure

## Cloud Storage Extension

Use Cloud Storage Extension when the user wants an extension-based path for structured object-storage files rather than native `IMPORT` or `EXPORT`.

Use it when:

- The workflow is already built around the extension
- The user is importing Parquet, Avro, ORC, or supported Delta data through extension UDFs
- The user is exporting Exasol table data as Parquet through extension UDFs
- The user needs storage-specific extension behavior for Amazon S3, Google Cloud Storage, Azure Blob Storage, Azure Data Lake Gen1, or Azure Data Lake Gen2

Do not route simple native `IMPORT` or `EXPORT` cases here if Exasol SQL or `exapump` already fits the request more directly.

## Supported Scope

| Direction | Formats | Main entrypoint |
|-----------|---------|-----------------|
| Import | Parquet, Avro, ORC, supported Delta workflows | `IMPORT ... FROM SCRIPT CLOUD_STORAGE_EXTENSION.IMPORT_PATH WITH ...` |
| Export | Parquet | `EXPORT ... INTO SCRIPT CLOUD_STORAGE_EXTENSION.EXPORT_PATH WITH ...` |

Storage and format support is not identical for every combination. Before
generating a storage-specific workflow, check the user guide for the requested
system and format. The official guide has sections for Amazon S3, Google Cloud
Storage, Azure Blob Storage, Azure Data Lake Gen1, Azure Data Lake Gen2, Delta,
HDFS, and Alluxio.

## Setup Prerequisites

Before running transfer SQL, the extension must be deployed in Exasol:

1. The Cloud Storage Extension JAR must be available in BucketFS.
2. A schema such as `CLOUD_STORAGE_EXTENSION` must contain the extension UDF scripts.
3. Keep the UDF script names expected by the extension.

Required import UDF script names:

- `IMPORT_PATH`
- `IMPORT_METADATA`
- `IMPORT_FILES`

Required export UDF script names:

- `EXPORT_PATH`
- `EXPORT_TABLE`

Use **exasol-bucketfs** for BucketFS upload/list/remove operations. Use
**exasol-udfs** if the user needs to inspect or create the Java UDF script
definitions. In Exasol SaaS, the JAR may already exist in the SaaS BucketFS
location, but the available version can differ from public documentation.

Keep `IMPORT_METADATA` as `JAVA SCALAR SCRIPT ... EMITS (...)`; this is the
Cloud Storage Extension setup form and is allowed by Exasol script syntax.

Minimal setup shape:

The examples below assume the extension JAR was uploaded to the default BucketFS
bucket under `jars/`, matching the repository's BucketFS examples.

```sql
CREATE SCHEMA IF NOT EXISTS CLOUD_STORAGE_EXTENSION;
OPEN SCHEMA CLOUD_STORAGE_EXTENSION;

CREATE OR REPLACE JAVA SET SCRIPT IMPORT_PATH(...) EMITS (...) AS
  %scriptclass com.exasol.cloudetl.scriptclasses.FilesImportQueryGenerator;
  %jar /buckets/bfsdefault/default/jars/exasol-cloud-storage-extension-<version>.jar;
/

CREATE OR REPLACE JAVA SCALAR SCRIPT IMPORT_METADATA(...) EMITS (
  filename VARCHAR(2000),
  partition_index VARCHAR(100),
  start_index DECIMAL(36, 0),
  end_index DECIMAL(36, 0)
) AS
  %scriptclass com.exasol.cloudetl.scriptclasses.FilesMetadataReader;
  %jar /buckets/bfsdefault/default/jars/exasol-cloud-storage-extension-<version>.jar;
/

CREATE OR REPLACE JAVA SET SCRIPT IMPORT_FILES(...) EMITS (...) AS
  %scriptclass com.exasol.cloudetl.scriptclasses.FilesDataImporter;
  %jar /buckets/bfsdefault/default/jars/exasol-cloud-storage-extension-<version>.jar;
/

CREATE OR REPLACE JAVA SET SCRIPT EXPORT_PATH(...) EMITS (...) AS
  %scriptclass com.exasol.cloudetl.scriptclasses.TableExportQueryGenerator;
  %jar /buckets/bfsdefault/default/jars/exasol-cloud-storage-extension-<version>.jar;
/

CREATE OR REPLACE JAVA SET SCRIPT EXPORT_TABLE(...) EMITS (ROWS_AFFECTED INT) AS
  %scriptclass com.exasol.cloudetl.scriptclasses.TableDataExporter;
  %jar /buckets/bfsdefault/default/jars/exasol-cloud-storage-extension-<version>.jar;
/
```

## Connection Objects

Use connection objects for cloud credentials and pass the connection name into
the extension statement.

```sql
CREATE OR REPLACE CONNECTION S3_CONNECTION
TO ''
USER ''
IDENTIFIED BY 'S3_ACCESS_KEY=<aws_access_key>;S3_SECRET_KEY=<aws_secret_key>';
```

Use temporary token keys only when the selected storage authentication flow
requires them. For example, S3 can include `S3_SESSION_TOKEN`, Azure Blob can
use `AZURE_SAS_TOKEN`, and GCS can use connection-based key content in supported
Cloud Storage Extension versions. Keep all values as placeholders in skill
examples.

## Import Pattern

Use the extension import entrypoint when source files are in a supported
structured format and the workflow should use Cloud Storage Extension UDFs.

```sql
IMPORT INTO <schema>.<table>
FROM SCRIPT CLOUD_STORAGE_EXTENSION.IMPORT_PATH WITH
  BUCKET_PATH     = 's3a://<s3_path>/import/orc/data/*'
  DATA_FORMAT     = 'ORC'
  S3_ENDPOINT     = 's3.<region>.amazonaws.com'
  CONNECTION_NAME = 'S3_CONNECTION';
```

For GCS and Azure, use the storage-specific `BUCKET_PATH` scheme and required
parameters from the user guide. The target table must already exist and its
columns must match the data schema.

## Export Pattern

Use the extension export entrypoint when the user explicitly wants Cloud Storage
Extension Parquet export to object storage.

```sql
EXPORT <schema>.<table>
INTO SCRIPT CLOUD_STORAGE_EXTENSION.EXPORT_PATH WITH
  BUCKET_PATH     = 's3a://<s3_path>/export/parquet/data/'
  DATA_FORMAT     = 'PARQUET'
  S3_ENDPOINT     = 's3.<region>.amazonaws.com'
  CONNECTION_NAME = 'S3_CONNECTION';
```

Do not generate Avro, ORC, Delta, or CSV export examples for Cloud Storage
Extension.

## Parameters

Common required parameters:

- `BUCKET_PATH`: storage path, using the scheme expected by the selected storage system
- `DATA_FORMAT`: source or target file format
- Storage-specific access parameters, usually including `CONNECTION_NAME`

Common optional parameters:

- `PARALLELISM`: controls extension import/export parallelism; import and export interpret it differently
- `TIMEZONE_UTC`: controls timestamp timezone handling
- `CHUNK_SIZE` and `TRUNCATE_STRING`: import-only behavior
- `OVERWRITE`, `PARQUET_COMPRESSION_CODEC`, and `EXPORT_BATCH_SIZE`: export-only behavior

## Example Requests

Typical requests that belong in this skill:

```text
load Parquet files from object storage through Cloud Storage Extension
read ORC files from a bucket with the Cloud Storage Extension path
export a table as Parquet through Cloud Storage Extension
use the extension-based file reader instead of native IMPORT
```

## Practical Routing Rules

- If the user says `IMPORT INTO`, `CREATE CONNECTION`, `upload CSV`, or `upload Parquet` without extension intent, switch back to **exasol-import**
- If the user says `EXPORT INTO`, `export CSV`, `export local file`, or `exapump export` without extension intent, switch back to **exasol-export**
- If the user says `virtual schema`, `adapter`, `federated query`, or `read external tables without loading`, switch to **exasol-extension-catalog** to choose the right Virtual Schema path
- If the user asks which object-storage extension path fits the workflow, stay in this skill and choose the narrowest supported extension workflow

## Sources

- Exasol docs: https://docs.exasol.com/db/latest/loading_data/other_file_formats.htm
- Cloud Storage Extension repository: https://github.com/exasol/cloud-storage-extension
- Cloud Storage Extension user guide: https://github.com/exasol/cloud-storage-extension/blob/main/doc/user_guide/user_guide.md
