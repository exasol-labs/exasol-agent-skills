---
name: exasol-import
description: "Use Exasol `IMPORT` and `IMPORT INTO` SQL plus `exapump upload` local file workflows for moving data into Exasol. Covers CSV, FBV, and Parquet, `CREATE CONNECTION` connection objects for import, cloud credential patterns for S3, Azure Blob Storage, and Google Cloud Storage (GCS), reject handling, and staging-based import workflows. Native IMPORT does not read Avro, ORC, or Delta — those object-storage formats need the Cloud Storage Extension instead."
---

# Exasol Import Skill

This skill covers only workflows that move data into Exasol.

## Step 0: Establish Connection

Ensure a working `exapump` profile before giving terminal workflows that use
`exapump upload`:

1. If the user mentions a specific profile name, test it with `exapump sql --profile <name> "SELECT 1"`; always place `--profile` after the subcommand.
2. Otherwise, test the default profile with `exapump sql "SELECT 1"`.
3. If the check fails, run `exapump profile list`.
4. If profiles exist, ask which one to use and retry with `exapump sql --profile <name> "SELECT 1"`; keep `--profile` after the subcommand.
5. If a non-default profile is selected, include the same `--profile <name>` after the subcommand on subsequent `exapump` commands, such as `exapump upload --profile <name> <file> --table <schema.table>`.
6. If no profiles exist, tell the user to run `exapump profile add default` and retry.
7. Never read or reference the exapump configuration file.

Trigger when the user mentions **IMPORT**, **IMPORT INTO**, **upload CSV**, **upload Parquet**, **local file load**, **exapump upload**, **S3 import**, **Azure Blob import**, **GCS import**, **Parquet import**, or **CREATE CONNECTION** together with import or object-store loading intent.

## Routing Algorithm

1. **Local files on the user machine**
   - Trigger phrases: `upload csv`, `upload parquet`, `exapump upload`, `from local`
   - Load: `references/import.md`

2. **Remote or cloud files reachable by Exasol**
   - Trigger phrases: `IMPORT`, `IMPORT INTO`, `S3`, `Azure Blob`, `GCS`, `FTP`, `SFTP`, `HTTP`, `HTTPS`, `CREATE CONNECTION` with import or object-store loading intent
   - Load: `references/import.md`

3. **Parquet-specific behavior**
   - Trigger phrases: `parquet`, `SOURCE COLUMN NAMES`, `SkipCols`, `MaxConnections`, `MaxConcurrentReads`
   - Load: `references/import.md`

## Notes

- Use this skill only for direct data movement into Exasol.
- Use **exasol-export** for native `EXPORT`, local export workflows, and `CREATE CONNECTION` questions tied to export target setup.
- Use **exasol-database** for general `CREATE CONNECTION` questions, SQL, schema inspection, and table design.
- Use **exasol-cloud-storage-extension** when the user explicitly wants extension-based object-storage loading. Use **exasol-document-virtual-schemas** for federated read-only object or file storage access or **exasol-jdbc-virtual-schemas** for federated read-only database access. Use **exasol-extension-catalog** only when the user is still choosing among those families.
