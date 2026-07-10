# Adapter Development and Debugging

## When to Build a Custom Adapter

Build or customize an adapter only when one of these is true:

- no suitable maintained adapter already exists
- the source requires source-specific SQL dialect handling that generic JDBC does not cover well enough
- the workflow needs adapter behavior that must be changed in code

If a maintained adapter already exists, prefer using or extending that path before starting a new adapter from scratch.

## Generic JDBC Starting Point

For JDBC-accessible systems, the usual fallback model is:

1. start from the virtual schema framework and the common JDBC path
2. implement or adapt the source-specific dialect handling
3. package the adapter JAR
4. upload the JAR to BucketFS
5. create the Java adapter script
6. create the connection object
7. create the virtual schema and validate it with `EXPLAIN VIRTUAL`

This is the right path when the source behaves like a JDBC database but no dedicated maintained dialect adapter already fits.

## Build and Install Flow

Keep the build and install workflow practical:

1. prepare the adapter code and dependency set
2. build the deployable JAR
3. upload the JAR and required source driver JARs to BucketFS
4. create or update the adapter script to reference those JARs
5. create or update the connection object and schema properties
6. create the virtual schema or refresh the existing one
7. validate pushdown and metadata behavior

Typical installation pattern after the build:

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

## Security and Boundaries

- keep the adapter JAR, driver JARs, and connection-object configuration separate from real secrets in local helper files
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
- generic JDBC fallback if the source is JDBC-accessible and the behavior is close enough
- document-file adapter family if the source is file or object storage instead of a JDBC database

Avoid redesigning the broader adapter ecosystem when the user only needs one working source path.

## Practical Rules

- If the user only needs to create or query an existing JDBC virtual schema, switch to **exasol-jdbc-virtual-schemas**
- If the user only needs to create or query an existing document-file virtual schema, switch to **exasol-document-virtual-schemas**
- If the user needs to physically load data into Exasol instead of federating it, switch to **exasol-import** or **exasol-cloud-storage-extension**
