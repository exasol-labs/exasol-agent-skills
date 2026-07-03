---
name: exasol
description: Top-level router for Exasol work. Use for any Exasol database, exapump, SQL, BucketFS, UDF, Script Language Container, or Exasol Personal setup task, then route to the narrowest specialized Exasol skill.
---

# Exasol Router Skill

Use this skill whenever the user asks about Exasol. The user does not need to know internal skill names. Treat `/exasol <task>` and natural-language Exasol requests as the public interface.

## Routing Algorithm

Choose the narrowest matching route. If multiple routes apply, load them in dependency order.

1. **Exasol database, SQL, exapump, data import/export**
   - Trigger phrases: `SQL`, `query`, `SELECT`, `CREATE TABLE`, `IMPORT`, `EXPORT`, `upload CSV`, `upload Parquet`, `exapump`, `profile`, `schema`, `table`
   - Activate: **exasol-database**

2. **BucketFS file management**
   - Trigger phrases: `BucketFS`, `bfsdefault`, `bucket`, `upload jar`, `upload model`, `list files`, `download from bucket`, `delete bucket file`
   - Activate: **exasol-bucketfs**

3. **UDFs and Script Language Containers**
   - Trigger phrases: `UDF`, `CREATE SCRIPT`, `SCALAR`, `SET script`, `ExaIterator`, `Python UDF`, `Java UDF`, `Lua UDF`, `R UDF`, `SLC`, `Script Language Container`, `exaslct`
   - Activate: **exasol-udfs**

4. **Exasol Personal setup**
   - Trigger phrases: `set up Exasol`, `Exasol Personal`, `deploy Exasol`, `install Exasol on AWS`, `new Exasol database`
   - Activate: **exasol-setup-personal**

## Dependency Order

When setup and usage both apply, resolve prerequisites first:

1. Exasol Personal or external database availability
2. exapump profile or connection configuration
3. BucketFS or database connectivity validation
4. SQL, data movement, BucketFS, UDF, or SLC task

## User Interaction Rules

- Do not ask the user to choose a sub-skill.
- Infer the route from the task.
- If the task is ambiguous, ask one concrete question about the desired outcome, not about internal skill names.
- Prefer `/exasol <task>` in examples.
- Do not expose implementation labels such as `exasol-database` unless the user is contributing to this repo.

## Adding Routes

When adding a new specialized Exasol skill, update this router and mirror the same intent route in `plugins/exasol/commands/exasol.md`. Keep the new skill focused on its domain and put detailed docs in `references/`.
