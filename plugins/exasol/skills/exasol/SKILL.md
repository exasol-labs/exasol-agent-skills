---
name: exasol
description: Top-level router for Exasol work. Use for any Exasol database, exapump, SQL, BucketFS, extension, integration, UDF, Script Language Container, or Exasol Personal setup task, then route to the narrowest specialized Exasol skill.
---

# Exasol Router Skill

Use this skill whenever the user asks about Exasol. The user does not need to know internal skill names. Treat `/exasol <task>` and natural-language Exasol requests as the public interface.

## Routing Algorithm

Choose the narrowest matching route. If multiple routes apply, load them in dependency order.

1. **Exasol database, SQL, exapump, data import/export**
   - Trigger phrases: `SQL`, `query`, `SELECT`, `CREATE TABLE`, `IMPORT`, `EXPORT`, `upload CSV`, `upload Parquet`, `exapump`, `profile`, `schema`, `table`
   - Activate: **exasol-database**

2. **Import workflows**
   - Trigger phrases: `IMPORT INTO`, `upload CSV`, `upload Parquet`, `local file load`, `S3 import`, `Azure Blob import`, `GCS import`, `CREATE CONNECTION`, `Parquet import`
   - Activate: **exasol-import**

3. **Notebook-connector AI setup**
   - Trigger phrases: `Secrets`, `scs`, `secure config store`, `notebook-connector setup`, `db_host_name`, `db_schema`, `storage_backend`, `huggingface_token`
   - Activate: **exasol-ai-setup**

4. **Transformers Extension workflows**
   - Trigger phrases: `Transformers Extension`, `TE extension`, `initialize_te_extension`, `deploy_scripts`, `TE UDF`, `PYTHON3_TE`, `Hugging Face models in Exasol`
   - Activate: **exasol-transformers**

5. **Exasol tools, extensions, connectors, integrations, and architecture patterns**
   - Trigger phrases: `extension`, `connector`, `integration`, `catalog`, `tool`, `which Exasol tool`, `Virtual Schema adapter`, `MCP`, `Text-to-SQL`, `Lakehouse Turbo`, `Terraform`, `Ansible`, `Databricks`, `SAP`, `Power BI`, `Tableau`, `migration`, `governance`, `observability`, `semantic layer`, `Agent Control Plane`
   - Activate: **exasol-extension-catalog**

6. **BucketFS file management**
   - Trigger phrases: `BucketFS`, `bfsdefault`, `bucket`, `upload jar`, `upload model`, `list files`, `download from bucket`, `delete bucket file`
   - Activate: **exasol-bucketfs**

7. **Notebook-connector connection helpers**
   - Trigger phrases: `open_pyexasol_connection`, `open_sqlalchemy_connection`, `open_ibis_connection`, `open_bucketfs_bucket`, `open_bucketfs_location`, `get_backend`, `connection helper`, `notebook-connector`
   - Activate: **exasol-notebook-connections**

8. **UDFs and Script Language Containers**
   - Trigger phrases: `UDF`, `CREATE SCRIPT`, `SCALAR`, `SET script`, `ExaIterator`, `Python UDF`, `Java UDF`, `Lua UDF`, `R UDF`, `SLC`, `Script Language Container`, `exaslct`
   - Activate: **exasol-udfs**

9. **Exasol Personal setup**
   - Trigger phrases: `set up Exasol`, `Exasol Personal`, `deploy Exasol`, `install Exasol on AWS`, `new Exasol database`
   - Activate: **exasol-setup-personal**

## Dependency Order

When setup and usage both apply, resolve prerequisites first:

1. Exasol Personal or external database availability
2. Tool, extension, connector, or architecture selection
3. exapump profile or connection configuration
4. BucketFS or database connectivity validation
5. SQL, data movement, BucketFS, UDF, SLC, or integration task

## User Interaction Rules

- Do not ask the user to choose a sub-skill.
- Infer the route from the task.
- If the task is ambiguous, ask one concrete question about the desired outcome, not about internal skill names.
- Prefer `/exasol <task>` in examples.
- Do not expose implementation labels such as `exasol-database` unless the user is contributing to this repo.

## Adding Routes

When adding a new specialized Exasol skill, update this router and mirror the same intent route in `plugins/exasol/commands/exasol.md`. Keep the new skill focused on its domain and put detailed docs in `references/`.
