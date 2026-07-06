# LOAD Catalog

Use LOAD when the user wants to ingest, import, federate, stream, move, or query external data.

Support-level shorthand:

- Exasol-owned or Exasol-maintained: official Exasol docs and `github.com/exasol/...`.
- Exasol Labs/community: `github.com/exasol-labs/...`; verify the README and release status before production recommendations.
- Third-party ecosystem: vendor-owned tools and services documented by Exasol; verify vendor support details.

Version-specific notes are source-check reminders. Verify linked release notes or download pages before quoting current versions.

## Virtual Schemas

- **Use for**: federated access to external systems as virtual tables.
- **Best when**: user wants to query external data without copying it into Exasol.
- **Notable capabilities**: SQL access to external systems, optimizer pushdown for supported operations.
- **Links**:
  - https://github.com/exasol/virtual-schemas
  - https://github.com/exasol/exasol-virtual-schema
  - https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm

### Common Virtual Schema adapters

Use specific adapter repositories when the source is known:

- Athena: https://github.com/exasol/athena-virtual-schema
- Azure Blob document files: https://github.com/exasol/azure-blob-storage-document-files-virtual-schema
- Azure Data Lake Gen2 document files: https://github.com/exasol/azure-data-lake-storage-gen2-document-files-virtual-schema
- BigQuery: https://github.com/exasol/bigquery-virtual-schema
- Databricks: https://github.com/exasol/databricks-virtual-schema
- DB2: https://github.com/exasol/db2-virtual-schema
- DynamoDB: https://github.com/exasol/dynamodb-virtual-schema
- Elasticsearch: https://github.com/exasol/elasticsearch-virtual-schema
- Exasol: https://github.com/exasol/exasol-virtual-schema
- Generic JDBC: https://github.com/exasol/generic-jdbc-virtual-schema
- Google Cloud Storage document files: https://github.com/exasol/google-cloud-storage-document-files-virtual-schema
- HANA: https://github.com/exasol/hana-virtual-schema
- Hive: https://github.com/exasol/hive-virtual-schema
- Impala: https://github.com/exasol/impala-virtual-schema
- MySQL: https://github.com/exasol/mysql-virtual-schema
- Oracle: https://github.com/exasol/oracle-virtual-schema
- PostgreSQL: https://github.com/exasol/postgresql-virtual-schema
- Redis: https://github.com/exasol/redis-virtual-schema
- Redshift: https://github.com/exasol/redshift-virtual-schema
- S3 document files: https://github.com/exasol/s3-document-files-virtual-schema
- Snowflake: https://github.com/exasol/snowflake-virtual-schema
- SQL Server: https://github.com/exasol/sqlserver-virtual-schema
- Sybase ASE: https://github.com/exasol/sybase-virtual-schema

## Cloud Storage Extension

- **Use for**: reading files from object storage.
- **Best when**: user wants to read Parquet, Avro, ORC, CSV, or cloud object storage files.
- **Links**:
  - https://github.com/exasol/cloud-storage-extension

## Lakehouse Turbo

- **Use for**: current/productized lakehouse acceleration over object storage and open table formats.
- **Best when**: user needs lakehouse BI/ML/analytics acceleration now, with minimal architecture change and no full migration into Exasol.
- **Links**:
  - https://docs.exasol.com/db/latest/connect_exasol/lakehouse_turbo_as_app.htm

## exapump

- **Use for**: CLI import/export, SQL execution, Parquet/CSV movement, BucketFS operations.
- **Best when**: user wants a single binary for fast terminal-based data exchange.
- **Links**:
  - https://github.com/exasol-labs/exapump

## exarrow-rs

- **Use for**: Rust, Arrow, ADBC, and native protocol data exchange.
- **Best when**: user needs high-throughput Parquet/Arrow workflows or wants to build Rust/native integrations.
- **Links**:
  - https://github.com/exasol-labs/exarrow-rs

## exasol-json-tables

- **Use for**: JSON/NDJSON ingestion and JSON-native querying workflows on Exasol.
- **Best when**: user wants nested JSON workflows without core database changes.
- **Links**:
  - https://github.com/exasol-labs/exasol-json-tables

## database-migration

- **Use for**: migrating legacy/source databases to Exasol and running migration POCs.
- **Best when**: user wants scripts for source-to-Exasol migration, type mapping, customer POCs, migration validation, or post-load optimization.
- **Supported script families recently highlighted**: Db2, Exasol, MariaDB, MySQL, Netezza, Oracle, PostgreSQL, SAP HANA, SQL Server, Teradata, and ClickHouse.
- **Notable capabilities**: full data-type coverage emphasis, `CHECK_MIGRATION` source/target reconciliation, comment/view migration, consistent parameters, and post-load `convert_varchar` / `convert_datatypes` optimization.
- **Links**:
  - https://github.com/exasol/database-migration
  - https://github.com/exasol/database-migration/blob/master/README.md
  - https://github.com/exasol/database-migration/blob/master/post_load_optimization/README.md

## Streaming connectors

- **Kafka Connector Extension**
  - Use for Kafka and Azure Event Hubs.
  - Link: https://github.com/exasol/kafka-connector-extension
- **Kinesis Connector Extension**
  - Use for Amazon Kinesis Data Streams.
  - Link: https://github.com/exasol/kinesis-connector-extension

## Spark, Glue, ADF, and ETL tools

- **Spark Exasol Connector**: https://github.com/exasol/spark-connector
- **AWS Glue integration**: https://github.com/exasol/aws-glue-exasol-connector
- **Azure Data Factory Functions / Bulk Loader**: https://github.com/exasol/azure-data-factory-functions
- **Ecosystem ETL list**: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## Drivers and load/extract connectors

- **Recent update to verify**: JDBC 26.2.8, ODBC 26.2.7, EXAplus 26.2.8, and the ODBC Linux ARM64 driver were announced through the download portal; PyExasol 2.2.2 widened dependency ranges.
- JDBC: https://docs.exasol.com/db/latest/connect_exasol/drivers/jdbc.htm
- ODBC: https://docs.exasol.com/db/latest/connect_exasol/drivers/odbc.htm
- Exasol Download Portal: https://downloads.exasol.com/
- ADO.NET: https://docs.exasol.com/db/latest/connect_exasol/drivers/ado.net.htm
- PyExasol: https://github.com/exasol/pyexasol
- PyExasol 2.2.2: https://github.com/exasol/pyexasol/releases/tag/2.2.2
- SQLAlchemy Exasol: https://github.com/exasol/sqlalchemy-exasol
- Exasol TypeScript/JavaScript driver: https://github.com/exasol/exasol-driver-ts
- Go SQL Driver: https://github.com/exasol/exasol-driver-go
- R Integration: https://docs.exasol.com/db/latest/connect_exasol/drivers/r.htm
- WebSockets API: https://github.com/exasol/websocket-api
- Ibis backend: https://ibis-project.org/backends/exasol
