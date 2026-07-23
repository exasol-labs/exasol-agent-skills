# Adapter Development and Debugging

## Source Anchors

Use these as starting points before inventing implementation details:

- Virtual Schemas overview and common framework: https://github.com/exasol/virtual-schemas
- Common JDBC adapter framework: https://github.com/exasol/virtual-schema-common-jdbc
- Generic JDBC adapter reference implementation: https://github.com/exasol/generic-jdbc-virtual-schema — use as a code reference only after checking current repository status, not as an unconditional production recommendation
- Maintained JDBC adapter examples: use the closest source-specific adapter from the extension catalog before starting from scratch
- Maintained document-file adapter examples: S3, Google Cloud Storage, Azure Blob Storage, and Azure Data Lake Storage Gen2 document-file virtual schema repositories listed in the extension catalog

Check the selected repository's current README, release notes, Java version, build tool, and debugger documentation before giving version-specific commands.

If the user is still deciding which maintained adapter or extension to use, switch to **exasol-extension-catalog** first. Return here only when the task requires adapter code, custom packaging, dialect behavior, or adapter-side debugging.

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

## Document-File Adapter Development Boundary

Most document-file virtual schema tasks should stay in **exasol-document-virtual-schemas** because they use maintained S3, Google Cloud Storage, Azure Blob Storage, or Azure Data Lake Storage Gen2 adapter families.

Use this adapter-development skill for document-file work only when the user must change adapter code, for example:

- implementing support for a new object-store API or document source that is not covered by a maintained adapter
- changing metadata inference, EDML mapping interpretation, or document path handling in adapter code
- debugging adapter-side failures that cannot be explained by connection JSON, `MAPPING`, BucketFS mapping files, or `EXPLAIN VIRTUAL`

Do not duplicate normal document-file setup examples here. For connection JSON, mapping-file, and existing adapter-family usage, route to **exasol-document-virtual-schemas**.

Document-file adapter implementation landmarks vary by repository. Before giving code-level advice, inspect the selected repository for its documented metadata reader, storage client, mapping parser, integration-test fixtures, and supported Java/build versions.

## Custom JDBC Dialect Implementation Checklist

When implementing source-specific behavior, cover these areas explicitly:

1. choose the closest maintained adapter or `virtual-schema-common-jdbc` example as the starting point
2. implement the source dialect behavior for identifier quoting, case handling, literals, predicates, `LIMIT`/pagination, date/time syntax, and function rendering
3. map source data types to Exasol-compatible virtual schema metadata and document lossy or unsupported mappings
4. declare pushdown capabilities only where the source semantics are safe, including filters, projections, aggregates, joins, ordering, and limits
5. implement metadata discovery for catalogs, schemas, tables, columns, nullability, precision, scale, and comments where supported
6. validate adapter properties from `CREATE VIRTUAL SCHEMA ... WITH` and return actionable validation errors
7. document unsupported operations instead of silently generating unsafe remote SQL

Schematic implementation map; exact class names vary by repository version, so inspect the selected adapter framework before writing code:

```text
src/main/java/.../<Source>SqlDialect.java       # SQL rendering, capabilities, type mapping
src/main/java/.../<Source>AdapterFactory.java   # adapter/dialect wiring if used by the framework
src/main/java/.../<Source>MetadataReader.java   # source metadata discovery if custom discovery is required
src/test/java/.../<Source>SqlDialectTest.java   # unit tests for generated SQL and capability decisions
src/test/java/.../<Source>IntegrationTest.java  # Exasol + representative source validation when available
```

Keep examples schematic unless the user has selected a concrete adapter repository and version.

Minimum test expectations for a custom JDBC dialect change:

```text
<Source>SqlDialectTest
- renders quoted and unquoted identifiers according to the source rules
- renders string, numeric, date, timestamp, and NULL literals correctly
- renders supported filters, functions, ORDER BY, and LIMIT/pagination syntax
- rejects or marks unsupported pushdown capabilities instead of generating unsafe SQL

<Source>MetadataReaderTest or integration test
- maps representative source types to Exasol virtual-schema metadata
- preserves precision, scale, nullability, and case behavior where supported
- returns actionable errors for invalid schema properties without exposing secrets
```

Use repository-native test classes and assertions after selecting a concrete codebase; do not invent framework APIs from these schematic names.

## Adapter Property Design

Design properties as a stable user-facing contract:

- require only properties that are necessary for connection, schema selection, or behavior flags
- provide defaults for optional behavior where safe
- validate required properties before connecting to the source
- return clear errors for unknown, deprecated, or incompatible property combinations
- preserve backward compatibility for renamed properties where practical
- document each property with purpose, allowed values, default, and whether it can be changed with `ALTER VIRTUAL SCHEMA ... SET`
- never use properties to carry secrets when a connection object can hold credentials instead

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

```sh
# Inspect the selected adapter repository first; these commands are placeholders.
./mvnw clean verify
./mvnw package -DskipTests
exapump bucketfs cp target/<adapter-artifact>-<version>.jar jars/<adapter-artifact>-<version>.jar
exapump bucketfs cp /path/to/<source-driver>-<version>.jar jars/<source-driver>-<version>.jar
```

Use the repository's documented Maven or Gradle wrapper if it provides one. Do not invent release commands, signing steps, or deployment targets that are not documented by the selected repository.

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

Minimal post-install smoke-test sequence:

```text
SELECT * FROM src_vs."VIRTUAL_TABLE_NAME" LIMIT 1;

EXPLAIN VIRTUAL
SELECT *
FROM src_vs."VIRTUAL_TABLE_NAME"
WHERE "FILTER_COLUMN" = 'PLACEHOLDER_VALUE';

ALTER VIRTUAL SCHEMA src_vs REFRESH;
```

Keep table, column, and literal values as placeholder names unless the user provides non-sensitive values for immediate execution.

## Packaging and Dependency Rules

- keep the custom adapter JAR and source JDBC driver JAR responsibilities clear; the adapter JAR contains adapter code, while the driver JAR belongs to the source system
- avoid bundling multiple conflicting JDBC drivers unless the selected repository explicitly documents that pattern
- record exact adapter, framework, source driver, Java, and Exasol versions used for the smoke test
- use reproducible build commands from the selected repository rather than inventing new build steps
- upload versioned artifact names to BucketFS so rollbacks do not depend on overwriting a single mutable file name
- after replacing an adapter JAR, recreate or refresh the Java adapter script and run the smoke-test validation again

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

Adapter-development validation matrix:

| Area | Minimum check |
|------|---------------|
| Metadata | table list, column names, nullability, precision, scale, and type mapping |
| Simple query | projection from one virtual table |
| Filter pushdown | representative equality, range, null, and string predicates |
| Aggregation | `GROUP BY`, aggregate functions, and unsupported aggregate behavior when relevant |
| Join behavior | pushdown only when the adapter declares safe join support |
| Ordering and limits | generated remote SQL matches source dialect semantics |
| Refresh | `ALTER VIRTUAL SCHEMA ... REFRESH` updates changed source metadata |
| Errors | invalid properties and source failures produce actionable messages without leaking secrets |

Unit tests should focus on SQL generation, type mapping, property validation, and capability decisions. Integration tests should use Exasol plus a representative source system when the adapter repository supports it.

## Remote Debugging

Remote debugging is an adapter-development workflow, not a normal query workflow.

Use it when:

- the adapter logic itself is failing
- pushdown generation or property handling needs adapter-side inspection
- SQL-level checks such as `EXPLAIN VIRTUAL` are not enough

When the user asks for remote debugging, stay aligned with the adapter repository's documented debugger setup instead of inventing a custom procedure.

Remote debugging safety rules:

- bind debug listeners to localhost, a private test network, or the repository-documented secure path; do not expose debug ports broadly
- use short-lived test credentials and non-production source systems where possible
- redact connection strings, user names, tokens, hostnames, generated SQL containing sensitive literals, and customer data before sharing logs
- remove temporary debug flags and rebuild/redeploy the normal artifact after debugging

Debugging order:

1. reproduce with the smallest `SELECT` against one virtual table
2. run `EXPLAIN VIRTUAL` and inspect generated remote SQL
3. verify the connection object and non-secret schema properties
4. compare generated SQL with a query that succeeds directly on the source system
5. inspect adapter logs or diagnostics documented by the selected repository
6. use remote debugging only after SQL-level and metadata checks are insufficient

## Dialect and Scope Decisions

Keep the adapter as narrow as the source requires:

- dedicated maintained adapter if one already exists
- `virtual-schema-common-jdbc` based development if the source is JDBC-accessible but needs source-specific dialect behavior
- document-file adapter family if the source is file or object storage instead of a JDBC database

Avoid redesigning the broader adapter ecosystem when the user only needs one working source path.

## Release Readiness Checklist

Before handing off a custom adapter change, confirm:

- supported source versions and limitations are documented
- adapter properties and defaults are documented
- smoke-test SQL for `CREATE JAVA ADAPTER SCRIPT` and `CREATE VIRTUAL SCHEMA` uses placeholders only
- unit and integration tests relevant to the changed dialect behavior pass
- artifact names and versions are recorded
- known unsupported pushdowns are listed
- generated examples, logs, and comments do not contain credentials, tokens, customer hosts, or customer data
- normal setup/query/refresh usage is still routed to **exasol-jdbc-virtual-schemas** or **exasol-document-virtual-schemas** rather than duplicated here

## Practical Rules

- If the user only needs to create or query an existing JDBC virtual schema, switch to **exasol-jdbc-virtual-schemas**
- If the user only needs to create or query an existing document-file virtual schema, switch to **exasol-document-virtual-schemas**
- If the user asks which adapter family, connector, or extension to choose, switch to **exasol-extension-catalog** before development guidance
- If the user needs to physically load data into Exasol instead of federating it, switch to **exasol-import** or **exasol-cloud-storage-extension**
