---
name: exasol-extension-catalog
description: Catalog and routing guide for Exasol tools, extensions, connectors, integrations, and architecture patterns. Use when users ask how to extend, customize, deploy, load, explore, enrich, surface, scale, automate, govern, migrate, or integrate Exasol, including Exasol Labs tools, AI/ML, UDFs, lakehouse, SAP, Databricks, agentic workflows, or product/version status.
---

# Exasol Extension Catalog Skill

Last reviewed: 2026-07-03.

Use this skill when a user asks how to extend, customize, integrate, deploy, operate, automate, enrich, expose, or scale Exasol.

The catalog organizes Exasol capabilities into six categories:

- **DEPLOY**: provision, install, package, configure, schedule, and operate Exasol.
- **LOAD**: ingest, import, federate, stream, move, or query external data.
- **EXPLORE**: inspect schemas, query data, use notebooks, BI tools, catalogs, and agentic query interfaces.
- **ENRICH**: add AI, ML, UDFs, text processing, semantic interpretation, agents, and custom computation.
- **SURFACE**: expose Exasol to humans, applications, BI, APIs, low-code tools, and agents.
- **SCALE**: improve scale-out, performance, reliability, governance, observability, testing, repeatability, and enterprise operations.

## Important Use Rules

1. Prefer official Exasol docs or GitHub repositories when giving installation or configuration instructions.
2. Distinguish between Exasol-owned or Exasol-maintained tools, Exasol Labs/community tools, and third-party ecosystem integrations.
3. For customer-facing recommendations, state support level when known. If support level is not explicit in the reference, verify the linked source before presenting it as supported.
4. For current versions, latest releases, security status, or support status, check the linked source before answering.
5. For destructive operations, deployment changes, credential management, RBAC, Terraform, or agent automation, include safety and rollback guidance.
6. For agentic workflows, prefer governed patterns: MCP Server, Agent Control Plane, semantic layer, SQL guardrails, audit logs, and least-privilege credentials.

## Routing Algorithm

Choose the narrowest matching category and load only the matching reference files. If multiple categories apply, load all relevant references before answering.

1. **Run Exasol somewhere or operate deployment tooling**
   - Trigger phrases: `deploy`, `install`, `Exasol SaaS`, `Exasol Personal`, `Docker DB`, `Terraform`, `Ansible`, `scheduler`, `public keys`, `artifact verification`, `Extension Manager`
   - Load: `references/deploy.md`

2. **Bring data into Exasol or query data elsewhere**
   - Trigger phrases: `load`, `ingest`, `import`, `federate`, `Virtual Schema`, `Databricks`, `SAP HANA`, `Snowflake`, `Oracle`, `PostgreSQL`, `Kafka`, `Kinesis`, `Spark`, `Glue`, `Azure Data Factory`, `migration`, `driver`, `ODBC`, `JDBC`, `PyExasol`
   - Load: `references/load.md`

3. **Understand data or query it interactively**
   - Trigger phrases: `explore`, `MCP`, `Text-to-SQL`, `VS Code`, `AI Lab`, `Notebook Connector`, `SQL client`, `catalog`, `semantic layer`, `metadata`
   - Load: `references/explore.md`

4. **Add AI, ML, UDFs, text analytics, or agents**
   - Trigger phrases: `AI`, `ML`, `transformers`, `sentiment`, `entity extraction`, `SageMaker`, `MLflow`, `model UDF`, `foundation model`, `Agent Control Plane`, `Rust UDF`, `Metadata Agent`
   - Load: `references/enrich.md`

5. **Expose Exasol to apps, BI, APIs, users, or agents**
   - Trigger phrases: `BI`, `dashboard`, `Tableau`, `Power BI`, `Superset`, `REST API`, `ERA`, `Power Apps`, `low-code`, `application driver`, `CData`, `Denodo`, `Trino`
   - Load: `references/surface.md`

6. **Improve scale, governance, performance, observability, repeatability, or reliability**
   - Trigger phrases: `scale`, `performance`, `governance`, `RBAC`, `observability`, `CloudWatch`, `telemetry`, `SBOM`, `testing`, `CI`, `change management`, `data protection`, `warehouse automation`
   - Load: `references/scale.md`

## Fast Routing Guide

- User wants to run Exasol somewhere: use **DEPLOY**.
- User wants to bring data into Exasol or query data elsewhere: use **LOAD**.
- User wants to understand data or query it interactively: use **EXPLORE**.
- User wants AI, ML, UDFs, text analytics, or agents: use **ENRICH**.
- User wants to expose Exasol to apps, BI, APIs, users, or agents: use **SURFACE**.
- User wants production scale, governance, performance, observability, repeatability, or reliability: use **SCALE**.

## Related Skills

- Use **exasol-database** for direct SQL, exapump, table design, and query profiling after choosing the relevant tool family.
- Use **exasol-import** for direct native `IMPORT`, local CSV or Parquet loading, connection objects for import, and native Parquet loading behavior.
- Use **exasol-export** for direct native `EXPORT`, local file export, and connection objects for export.
- Use **exasol-bucketfs** for BucketFS file upload, download, list, and delete workflows.
- Use **exasol-udfs** for UDF and Script Language Container implementation details.
- Use **exasol-ai-setup** and **exasol-notebook-connections** for notebook-connector configuration and Python connection helpers.
- Use **exasol-setup-personal** for guided Exasol Personal deployment.
