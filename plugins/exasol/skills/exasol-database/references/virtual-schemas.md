# Virtual Schemas

Virtual Schemas provide read-only access to external data sources as if they were native Exasol tables.

## Create a Virtual Schema

```sql
-- 1. Create the adapter script (Java)
CREATE OR REPLACE JAVA ADAPTER SCRIPT adapter_schema.jdbc_adapter AS
  %scriptclass com.exasol.adapter.RequestDispatcher;
  %jar /buckets/bfsdefault/default/virtual-schema-dist-12.0.0.jar;
  %jar /buckets/bfsdefault/default/postgresql-42.7.1.jar;
/

-- 2. Create a connection object for the remote database
CREATE OR REPLACE CONNECTION pg_conn
TO 'jdbc:postgresql://host:5432/mydb'
USER 'user' IDENTIFIED BY 'password';

-- 3. Create the virtual schema
CREATE VIRTUAL SCHEMA pg_schema
USING adapter_schema.jdbc_adapter
WITH CONNECTION_NAME = 'PG_CONN'
     SCHEMA_NAME = 'public';
```

## Query Virtual Schemas

```sql
-- Queries are pushed down to the remote source where possible
SELECT * FROM pg_schema.remote_table WHERE id > 100;
```

## Limitations

- **Read-only**: No INSERT, UPDATE, DELETE, or MERGE on virtual tables
- **64 MiB statement limit**: Responses from the adapter must fit in 64 MiB
- **IS_LOCAL optimization**: Mark a virtual schema as `IS_LOCAL` if the remote source is co-located, enabling the optimizer to skip network cost estimates
- **Pushdown scope**: The adapter decides which operations (filters, joins, aggregations) to push down

## Refresh Metadata

```sql
ALTER VIRTUAL SCHEMA pg_schema REFRESH;
```
