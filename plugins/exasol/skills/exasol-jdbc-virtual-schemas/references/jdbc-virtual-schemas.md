# JDBC Virtual Schema Workflows

## Scope

JDBC-based virtual schemas expose external databases as virtual tables inside Exasol. Use them when the user wants federated queries and the source data should remain outside Exasol.

Virtual schemas are primarily used for federated read queries. They can also be used to copy data into Exasol via `INSERT ... SELECT` from virtual tables, but this is slower than native IMPORT or the Cloud Storage Extension — prefer those for bulk loading.

## Basic Creation Pattern

Use this setup shape for JDBC/database-source virtual schemas:

1. Upload the virtual schema adapter JAR and required JDBC driver JARs to BucketFS.
2. Create the Java adapter script that points to those JARs.
3. Create an Exasol connection object for the remote source.
4. Create the virtual schema with the adapter script and adapter properties.
5. Query the virtual schema like regular Exasol tables.

Example pattern with safe placeholders:

```sql
CREATE OR REPLACE JAVA ADAPTER SCRIPT "ADAPTER_SCHEMA"."JDBC_ADAPTER" AS
  %scriptclass com.exasol.adapter.RequestDispatcher;
  %jar /buckets/bfsdefault/default/jars/<virtual-schema-adapter-jar>.jar;
  %jar /buckets/bfsdefault/default/jars/<jdbc-driver-jar>.jar;
/

CREATE OR REPLACE CONNECTION "SRC_CONN"
TO 'jdbc:<driver>://<source-host>:<port>/<database-name>'
USER '<source-user>' IDENTIFIED BY '<source-password>';

CREATE VIRTUAL SCHEMA "SRC_VS"
USING "ADAPTER_SCHEMA"."JDBC_ADAPTER"
WITH CONNECTION_NAME = 'SRC_CONN'
     SCHEMA_NAME = '<source-schema>';
```

Use the adapter-specific repository or documentation before filling in JAR names, JDBC URL shape, and supported adapter properties.

## Adapter Family Selection

Prefer the narrowest maintained adapter family that fits the source.

Examples of maintained database-source adapter families listed in the catalog include Exasol, PostgreSQL, MySQL, Oracle, SQL Server, DB2, HANA, Snowflake, Redshift, Hive, Impala, Databricks, Athena, BigQuery, and Sybase ASE.

Do not document every dialect in equal depth inside the skill. Pick the matching maintained adapter, then check that adapter's README or release docs for exact properties and current limitations.

## Querying and Pushdown

Query virtual schema objects as read-only tables:

```sql
SELECT *
FROM "SRC_VS"."REMOTE_TABLE"
WHERE "ID" > 100;
```

Use `EXPLAIN VIRTUAL` when the user needs to inspect what is pushed down to the source:

```sql
EXPLAIN VIRTUAL
SELECT *
FROM "SRC_VS"."REMOTE_TABLE"
WHERE "ID" > 100;
```

`EXPLAIN VIRTUAL` is a SQL-level diagnostic for the generated remote query. It is useful for pushdown questions, unexpected filter/join behavior, and source-side performance investigation.

## Refresh and Metadata Operations

Use a full refresh when source metadata changed broadly:

```sql
ALTER VIRTUAL SCHEMA "SRC_VS" REFRESH;
```

Use a narrower table refresh when only specific source tables changed and the adapter supports that workflow:

```sql
ALTER VIRTUAL SCHEMA "SRC_VS" REFRESH TABLES "REMOTE_TABLE";
```

For table filtering or adapter-specific metadata filters, use the property names documented by the selected adapter. Do not invent filter property names from another adapter.

## Modifying Virtual Schema Properties

Use `ALTER VIRTUAL SCHEMA ... SET` to update adapter properties after the virtual schema is created:

```sql
-- Change the connection used by the virtual schema
ALTER VIRTUAL SCHEMA "SRC_VS" SET CONNECTION_NAME = '<new-connection>';

-- Update any supported adapter property
ALTER VIRTUAL SCHEMA "SRC_VS" SET <PROPERTY_NAME> = '<new-value>';
```

Check the selected adapter's README or release documentation for the full list of supported properties and their effects.

## Troubleshooting

Check problems in this order:

1. Validate the Exasol connection object and remote source reachability.
2. Confirm the adapter JAR and JDBC driver JAR paths match the BucketFS upload location.
3. Check that `CONNECTION_NAME` matches the Exasol connection object name.
4. Run `EXPLAIN VIRTUAL` on a representative query to inspect pushdown.
5. Run `ALTER VIRTUAL SCHEMA ... REFRESH` or `REFRESH TABLES ...` when metadata is stale.
6. If behavior depends on adapter internals, read the selected adapter repository and its troubleshooting or debugging guidance.

## Security and Boundaries

- Keep source credentials in Exasol connection objects instead of adapter script text.
- Use safe placeholders in examples; do not write real hosts, usernames, passwords, tokens, or customer data into skill files, scratch files, or review comments.
- Prefer least-privilege source accounts that can read only the needed schemas or tables.
- Do not bypass source-system authorization or Exasol connection-object privileges.
- Do not place credentials in BucketFS paths, adapter properties, SQL comments, or log snippets.

## Practical Routing Rules

- If the user wants federated querying of a JDBC/database source, stay in this skill.
- If the user wants to efficiently bulk-copy data into Exasol, use **exasol-import** or **exasol-cloud-storage-extension** based on the source/file path. Virtual schemas can also copy data via `INSERT ... SELECT` but are slower.
- If the user wants to export data out of Exasol, use **exasol-export**.
- If no maintained JDBC dialect fits and custom dialect code is required, use **exasol-virtual-schema-adapter-development**.
- If the user asks which Exasol integration family to use and the source is unclear, use **exasol-extension-catalog** first.
- If the user only needs to upload or inspect adapter JAR files in BucketFS, use **exasol-bucketfs**.

## Source Anchors

- Exasol SQL grammar in this repo for `CREATE VIRTUAL SCHEMA` and `ALTER VIRTUAL SCHEMA`.
- Exasol extension catalog in this repo for maintained virtual-schema adapter families and repository links.
