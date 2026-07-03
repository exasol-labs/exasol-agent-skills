# SCALE Catalog

Use SCALE when the user wants production scale, governance, performance, observability, repeatability, or reliability.

Support-level shorthand:

- Exasol-owned or Exasol-maintained: official Exasol docs and `github.com/exasol/...`.
- Exasol Labs/community: `github.com/exasol-labs/...`; verify the README and release status before production recommendations.
- Third-party ecosystem: vendor-owned tools and services documented by Exasol; verify vendor support details.

Version-specific notes are source-check reminders. Verify linked release notes or download pages before quoting current versions.

## Exasol core MPP architecture and cluster sizing

- **Use for**: horizontal scale-out and analytical performance.
- **Best when**: user asks how Exasol scales compute/data processing.
- **Links**:
  - https://docs.exasol.com/db/latest/home.htm
  - https://github.com/exasol/exasol-personal

## Lakehouse Turbo

- **Use for**: scaling performance over lakehouse/object-storage data with the current/productized acceleration layer.
- **Best when**: user wants fast repeated queries against lakehouse data today.
- **Links**:
  - https://docs.exasol.com/db/latest/connect_exasol/lakehouse_turbo_as_app.htm

## Virtual Schemas

- **Use for**: scaling data access through federation and pushdown.
- **Best when**: user wants to avoid copying all data into Exasol.
- **Links**:
  - https://github.com/exasol/virtual-schemas
  - https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm

## Exasol Terraform Provider

- **Use for**: scaling governance, RBAC, schema/connection management, and drift detection.
- **Best when**: user wants predictable database changes across environments.
- **Links**:
  - https://registry.terraform.io/providers/exasol-labs/exasol/latest/docs

## database-migration

- **Use for**: scaling migration reliability, POC speed, source/target validation, and post-load optimization.
- **Best when**: user needs repeatable migrations from major databases into Exasol or proof artifacts for customer sign-off.
- **Links**:
  - https://github.com/exasol/database-migration

## CloudWatch Adapter

- **Use for**: AWS CloudWatch observability.
- **Best when**: user needs Exasol monitoring surfaced into CloudWatch.
- **Links**:
  - https://github.com/exasol/cloudwatch-adapter

## Artifact verification and runtime supply-chain trust

- **Use for**: verifying Exasol artifacts and improving UDF runtime supply-chain observability.
- **Best when**: user asks about signed artifacts, public keys, SBOM scanning, Docker image provenance, or runtime dependency visibility.
- **Tools**:
  - Exasol public GPG keys: official source for artifact verification keys, key rotation, and expired keys.
  - Script Languages Release 11.2.0: preserves package-manager metadata in generated SLC images so SBOM tools such as `syft` can detect Debian packages correctly.
- **Links**:
  - https://docs.exasol.com/db/latest/connect_exasol/public_keys.htm
  - https://github.com/exasol/script-languages-release/releases/tag/11.2.0

## Telemetry Java

- **Use for**: anonymous telemetry in Java-based tools such as Virtual Schemas.
- **Best when**: building or maintaining tools that need usage telemetry.
- **Links**:
  - https://github.com/exasol/telemetry-java

## exasol-scheduler

- **Use for**: scaling operational workflows.
- **Best when**: user wants simple, SQL-auditable job orchestration.
- **Links**:
  - https://github.com/exasol-labs/exasol-scheduler

## High-throughput data movement

- exarrow-rs: https://github.com/exasol-labs/exarrow-rs
- exapump: https://github.com/exasol-labs/exapump
- Cloud Storage Extension: https://github.com/exasol/cloud-storage-extension
- Parquet IO Java: https://github.com/exasol/parquet-io-java

## Testing and development scale

Use these when the user wants repeatable CI, integration testing, Java testing utilities, or local test environments:

- Exasol Testcontainers: https://github.com/exasol/exasol-testcontainers
- Integration Test Docker Environment: https://github.com/exasol/integration-test-docker-environment
- Test DB Builder: https://github.com/exasol/test-db-builder-java
- SQL Statement Builder: https://github.com/exasol/sql-statement-builder
- jOOQ: https://www.jooq.org/
- Java Testcontainers: https://testcontainers.com/
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm

## Change management, data protection, and warehouse automation

- Sqitch: https://sqitch.org/
- Protegrity: https://www.protegrity.com/
- Datavault Builder: https://datavault-builder.com/
- datavault4dbt: https://github.com/ScalefreeCOM/datavault4dbt
- WhereScape: https://www.wherescape.com/
- Airflow: https://airflow.apache.org/
- dbt: https://www.getdbt.com/
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm
