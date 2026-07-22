# Adapter Development and Debugging

## When to Build a Custom Adapter

Build or customize an adapter only when one of these is true:

- no suitable maintained adapter already exists
- the source requires source-specific SQL dialect handling that an existing maintained adapter does not cover well enough
- the workflow needs adapter behavior that must be changed in code

If a maintained adapter already exists, prefer using or extending that path before starting a new adapter from scratch.

## JDBC Adapter Development Starting Point

For JDBC-accessible systems that need custom adapter behavior, the usual development model is:

1. start from the virtual schema framework and `virtual-schema-common-jdbc`
2. implement or adapt the source-specific dialect handling
3. package the adapter JAR
4. upload the JAR to BucketFS
5. create the Java adapter script
6. create the connection object
7. create the virtual schema and validate it with `EXPLAIN VIRTUAL`

This is the right path when the source behaves like a JDBC database but no dedicated maintained dialect adapter already fits. If the user only needs to configure an existing maintained adapter, route to **exasol-jdbc-virtual-schemas** instead.

## Build and Install Flow

Keep the build and install workflow practical:

1. prepare the adapter code and dependency set
2. build the deployable JAR
3. upload the JAR and required source driver JARs to BucketFS
4. create or update the adapter script to reference those JARs
5. create or update the connection object and schema properties
6. create the virtual schema or refresh the existing one
7. validate pushdown and metadata behavior

Schematic installation smoke-test pattern after the build:

```sql
CREATE OR REPLACE JAVA ADAPTER SCRIPT adapter_schema.jdbc_adapter AS
  %scriptclass com.exasol.adapter.RequestDispatcher;
  %jar /buckets/bfsdefault/default/jars/<adapter-jar-name>.jar;
  %jar /buckets/bfsdefault/default/jars/<source-driver-jar-name>.jar;
/

CREATE OR REPLACE CONNECTION src_conn
TO 'jdbc:<source-dialect>://<source-host>:<source-port>/<source-database>'
USER '<source-username>' IDENTIFIED BY '<source-password-secret>';

CREATE VIRTUAL SCHEMA src_vs
USING adapter_schema.jdbc_adapter
WITH CONNECTION_NAME = 'SRC_CONN'
     SCHEMA_NAME = 'public';
```

## Security and Boundaries

- keep the adapter JAR, driver JARs, and connection-object configuration separate from real secrets in local helper files
- use placeholders such as `<source-host>`, `<source-username>`, and `<source-password-secret>` in generated examples unless the user explicitly supplies values for immediate execution
- do not write real hosts, usernames, passwords, tokens, customer data, connection strings, or credentials into skill files, scratch files, comments, logs, or BucketFS paths
- never read or expose local exapump configuration files; they can contain credentials
- use least-privilege source credentials that fit the federated read-only workflow
- avoid expanding the scope from one required source path into a broader adapter redesign unless the user explicitly asks for that

## Validation Flow

Use this order:

1. connection validation
2. simple query against a virtual table
3. `EXPLAIN VIRTUAL` on a representative filtered query
4. metadata refresh checks
5. remote debugging only if the adapter code path still needs inspection

`EXPLAIN VIRTUAL` is the first SQL-level debugging tool when the question is "what is Exasol pushing down?" or "why is this adapter-generated query not behaving as expected?".

It shows the effective pushdown query without executing the remote workload itself.

## Remote Debugging

Remote debugging is an adapter-development workflow, not a normal query workflow.

Use it when:

- the adapter logic itself is failing
- pushdown generation or property handling needs adapter-side inspection
- SQL-level checks such as `EXPLAIN VIRTUAL` are not enough

When the user asks for remote debugging, stay aligned with the adapter repository's documented debugger setup instead of inventing a custom procedure.

## Dialect and Scope Decisions

Keep the adapter as narrow as the source requires:

- dedicated maintained adapter if one already exists
- `virtual-schema-common-jdbc` based development if the source is JDBC-accessible but needs source-specific dialect behavior
- document-file adapter family if the source is file or object storage instead of a JDBC database

Avoid redesigning the broader adapter ecosystem when the user only needs one working source path.

## Practical Rules

- If the user only needs to create or query an existing JDBC virtual schema, switch to **exasol-jdbc-virtual-schemas**
- If the user only needs to create or query an existing document-file virtual schema, switch to **exasol-document-virtual-schemas**
- If the user needs to physically load data into Exasol instead of federating it, switch to **exasol-import** or **exasol-cloud-storage-extension**
