# Document Virtual Schema Workflows

## What Virtual Schemas Are For

Document-file virtual schemas expose object or file storage as read-only virtual tables inside Exasol.

Use them when:

- the user wants federated queries instead of copying data into Exasol
- the source should remain external
- pushdown into the underlying system matters

Do not use them for write-back workflows. Virtual schemas are read-only.

Using virtual schemas to copy data into Exasol is technically possible but inefficient for bulk loads — prefer **exasol-import** or **exasol-cloud-storage-extension** for that use case.

## Basic Creation Pattern

Typical setup flow:

1. Upload the adapter JAR to BucketFS
2. Create the Java adapter scripts: the adapter script and the Java SET UDF script that loads the document data
3. Create or upload the EDML schema mapping file, or inline the mapping in the virtual schema properties
4. Create the connection object for the remote source using the JSON configuration expected by the selected adapter
5. Create the virtual schema with the adapter, connection, and `MAPPING` properties

Example pattern:

```sql
CREATE OR REPLACE JAVA ADAPTER SCRIPT adapter_schema.doc_adapter AS
  %scriptclass com.exasol.adapter.RequestDispatcher;
  %jar /buckets/bfsdefault/default/document-files-virtual-schema-dist-<version>.jar;
/

CREATE OR REPLACE JAVA SET SCRIPT adapter_schema.IMPORT_FROM_S3_DOCUMENT_FILES(
  DATA_LOADER VARCHAR(2000000),
  SCHEMA_MAPPING_REQUEST VARCHAR(2000000),
  CONNECTION_NAME VARCHAR(500))
  EMITS(...) AS
  %scriptclass com.exasol.adapter.document.UdfEntryPoint;
  %jar /buckets/bfsdefault/default/document-files-virtual-schema-dist-<version>.jar;
/

CREATE OR REPLACE CONNECTION doc_conn
TO ''
USER ''
IDENTIFIED BY '{
  "awsAccessKeyId": "<aws-access-key-id>",
  "awsSecretAccessKey": "<aws-secret-access-key>",
  "awsRegion": "<aws-region>",
  "s3Bucket": "<bucket-name>"
}';

CREATE VIRTUAL SCHEMA doc_vs
USING adapter_schema.doc_adapter
WITH
  CONNECTION_NAME = 'DOC_CONN'
  MAPPING = '/buckets/bfsdefault/default/path/to/mappings/in/bucketfs';
```

The `MAPPING` property points to one EDML mapping file or a BucketFS folder containing mapping files. For generated or test setups, the selected adapter can also accept inline EDML JSON in `MAPPING`; prefer uploaded mapping files for hand-maintained mappings.

## Adapter Family Selection

Choose the narrowest maintained adapter family that fits the source:

- **document-file virtual schemas** when the source is object or file storage rather than a JDBC database

Document-file adapter families called out in current Exasol references include:

- S3 document files
- Google Cloud Storage document files
- Azure Blob document files
- Azure Data Lake Gen2 document files

Choose the maintained document-file adapter family that matches the storage system instead of forcing a JDBC-oriented workflow onto object storage.

## Refresh and Metadata Operations

Use `ALTER VIRTUAL SCHEMA ... REFRESH` when the source metadata changed and the virtual schema should re-read it.

Use narrower refresh scope when the adapter supports it, instead of recreating the whole virtual schema every time. In practice this means:

- refresh only the affected tables when the change is limited
- use adapter-supported table filters where available
- keep full refresh for broad metadata changes or initial synchronization

If the exact refresh scope options matter for a specific adapter, check that adapter's documented properties before issuing the statement.

## Modifying Virtual Schema Properties

Use `ALTER VIRTUAL SCHEMA ... SET` to update adapter properties after the virtual schema is created:

```sql
-- Change the connection used by the virtual schema
ALTER VIRTUAL SCHEMA "DOC_VS" SET CONNECTION_NAME = '<new-connection>';

-- Update any supported adapter property
ALTER VIRTUAL SCHEMA "DOC_VS" SET <PROPERTY_NAME> = '<new-value>';
```

Check the selected adapter's README or release documentation for the full list of supported properties and their effects.

## Security and Privileges

- keep credentials in Exasol connection objects instead of embedding them in the adapter script text
- do not place real customer credentials, tokens, or connection strings into local scratch files or committed examples
- keep adapter and source access aligned with normal database and connection-object privileges
- do not suggest bypassing source-system authorization boundaries just to make federation work
- use sample placeholders in examples, not real hostnames, usernames, tokens, or datasets

## Troubleshooting and Debugging

Start with the workflow below:

1. Validate the connection object and source reachability first
2. Check that the correct adapter JAR is available to the adapter script
3. Run `EXPLAIN VIRTUAL` on a representative query to inspect the actual pushdown
4. If metadata is stale, run the appropriate refresh workflow
5. If the problem is adapter-side, check the adapter's GitHub repository for known issues and open a support ticket if needed.

`EXPLAIN VIRTUAL` is the first SQL-level debugging tool when the question is "what is Exasol pushing down?" or "why is this query not behaving as expected?".

It shows the effective pushdown query without executing the remote workload itself.

## Practical Rules

- If the user wants to query external data in place, stay in this skill
- If the user wants to physically load data into Exasol, switch to **exasol-import** or **exasol-cloud-storage-extension**
- If the source is a JDBC database rather than object or file storage, switch to **exasol-jdbc-virtual-schemas**
- If maintained document-file adapters are insufficient and custom adapter code is required, switch to **exasol-virtual-schema-adapter-development**
- If the source or integration family is still undecided, switch to **exasol-extension-catalog** before selecting an operational workflow
- If the user is deciding among available maintained document-file adapters, choose the storage-family-specific adapter that fits the source
