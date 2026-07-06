# Virtual Schema Workflows

## What Virtual Schemas Are For

Virtual schemas expose external systems as read-only virtual tables inside Exasol.

Use them when:

- the user wants federated queries instead of copying data into Exasol
- the source should remain external
- pushdown into the underlying system matters

Do not use them for write-back workflows. Virtual schemas are read-only.

## Basic Creation Pattern

Typical setup flow:

1. Upload the adapter JAR and any required driver JARs to BucketFS
2. Create the Java adapter script
3. Create the connection object for the remote source
4. Create the virtual schema with the adapter and connection properties

Example pattern:

```sql
CREATE OR REPLACE JAVA ADAPTER SCRIPT adapter_schema.jdbc_adapter AS
  %scriptclass com.exasol.adapter.RequestDispatcher;
  %jar /buckets/bfsdefault/default/virtual-schema-dist.jar;
  %jar /buckets/bfsdefault/default/source-driver.jar;
/

CREATE OR REPLACE CONNECTION src_conn
TO 'jdbc:postgresql://host:5432/mydb'
USER 'user' IDENTIFIED BY 'password';

CREATE VIRTUAL SCHEMA src_vs
USING adapter_schema.jdbc_adapter
WITH CONNECTION_NAME = 'SRC_CONN'
     SCHEMA_NAME = 'public';
```

## Adapter Family Selection

Choose the narrowest maintained adapter family that fits the source:

- dedicated SQL-dialect adapters when Exasol already maintains one for that source
- **generic JDBC** when the source is JDBC-accessible but there is no better dedicated maintained adapter for the workflow
- **document-file virtual schemas** when the source is object or file storage rather than a JDBC database

Document-file adapter families called out in current Exasol references include:

- S3 document files virtual schema
- BucketFS document files virtual schema
- Google Cloud Storage document files virtual schema
- Azure Blob Storage document files virtual schema
- Azure Data Lake Storage Gen2 document files virtual schema

Do not try to document every maintained dialect in equal depth inside this skill. Choose the dedicated maintained adapter when one already fits the source, otherwise fall back to generic JDBC when that source model is appropriate.

## Refresh and Metadata Operations

Use `ALTER VIRTUAL SCHEMA ... REFRESH` when the source metadata changed and the virtual schema should re-read it.

Use narrower refresh scope when the adapter supports it, instead of recreating the whole virtual schema every time. In practice this means:

- refresh only the affected tables when the change is limited
- use adapter-supported table filters where available
- keep full refresh for broad metadata changes or initial synchronization

If the exact refresh scope options matter for a specific adapter, check that adapter's documented properties before issuing the statement.

## Security and Privileges

- keep credentials in Exasol connection objects instead of embedding them in the adapter script text
- do not place real customer credentials, tokens, or connection strings into local scratch files or committed examples
- keep adapter and source access aligned with normal database and connection-object privileges
- do not suggest bypassing source-system authorization boundaries just to make federation work
- use sample placeholders in examples, not real hostnames, usernames, tokens, or datasets

## Troubleshooting and Debugging

Start with the workflow below:

1. Validate the connection object and source reachability first
2. Check that the correct adapter JAR and source driver JAR are available to the adapter script
3. Run `EXPLAIN VIRTUAL` on a representative query to inspect the actual pushdown
4. If metadata is stale, run the appropriate refresh workflow
5. If the problem is adapter-side, move to adapter logs or remote debugging

`EXPLAIN VIRTUAL` is the first SQL-level debugging tool when the question is "what is Exasol pushing down?" or "why is this query not behaving as expected?".

It shows the effective pushdown query without executing the remote workload itself.

## Remote Debugging

Remote debugging is an adapter-development workflow, not a normal query workflow.

Use it when:

- the adapter logic itself is failing
- pushdown generation or property handling needs adapter-side inspection
- SQL-level checks such as `EXPLAIN VIRTUAL` are not enough

When the user asks for remote debugging, stay aligned with the adapter repository's documented debugger setup instead of inventing a custom procedure.

## Practical Rules

- If the user wants to query external data in place, stay in this skill
- If the user wants to physically load data into Exasol, switch to **exasol-import-export** or **exasol-data-loading**
- If the user is deciding among available maintained source adapters, prefer the dedicated maintained adapter before falling back to generic JDBC
