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

2. **Exasol tools, extensions, connectors, integrations, and architecture patterns**
   - Trigger phrases: `extension`, `connector`, `integration`, `catalog`, `tool`, `which Exasol tool`, `Virtual Schema adapter`, `MCP`, `Text-to-SQL`, `Lakehouse Turbo`, `Terraform`, `Ansible`, `Databricks`, `SAP`, `Power BI`, `Tableau`, `migration`, `governance`, `observability`, `semantic layer`, `Agent Control Plane`
   - Activate: **exasol-extension-catalog**

3. **BucketFS file management**
   - Trigger phrases: `BucketFS`, `bfsdefault`, `bucket`, `upload jar`, `upload model`, `list files`, `download from bucket`, `delete bucket file`
   - Activate: **exasol-bucketfs**

4. **Notebook Connector AI setup**
   - Trigger phrases: `Secrets`, `secure config store`, `configure notebook-connector`, `AI setup`, `set up credentials for TE`, `set up credentials for TXAIE`
   - Activate: **exasol-ai-setup**

5. **Notebook Connector local Docker database workflows**
   - Trigger phrases: `bring_itde_up`, `restart_itde`, `get_itde_status`, `take_itde_down`, `ITDE`
   - Activate: **exasol-itde**

6. **Notebook Connector connection helpers**
   - Trigger phrases: `open_pyexasol_connection`, `open_sqlalchemy_connection`, `open_ibis_connection`, `open_bucketfs_bucket`, `open_bucketfs_location`, `get_backend`, `connection helper`, `notebook-connector`
   - Activate: **exasol-notebook-connections**

7. **Text AI Extension workflows**
   - Trigger phrases: `Text AI Extension`, `TXAIE`, `deploy_license`, `initialize_text_ai_extension`, `Extraction`, `NamedEntityExtractor`, `PipelineExtractor`, `BranchExtractor`, `PYTHON3_TXAIE`
   - Activate: **exasol-text-ai**

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
3. Notebook Connector AI setup when required
4. local Docker database lifecycle or helper-level connectivity validation
5. extension-specific TXAIE workflow
6. SQL, data movement, BucketFS, UDF, SLC, or integration task

## User Interaction Rules

- Do not ask the user to choose a sub-skill.
- Infer the route from the task.
- If the task is ambiguous, ask one concrete question about the desired outcome, not about internal skill names.
- Prefer `/exasol <task>` in examples.
- Do not expose implementation labels such as `exasol-database` unless the user is contributing to this repo.

## Adding Routes

When adding a new specialized Exasol skill, update this router and mirror the same intent route in `plugins/exasol/commands/exasol.md`. Keep the new skill focused on its domain and put detailed docs in `references/`.
