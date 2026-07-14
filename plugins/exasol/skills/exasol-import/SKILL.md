---
name: exasol-import
description: "Use Exasol IMPORT SQL plus exapump local file upload workflows for moving data into Exasol. Covers CSV, FBV, Parquet, connection objects, cloud credential patterns, reject handling, and staging-based import workflows."
---

# Exasol Import Skill

This skill covers only workflows that move data into Exasol.

## Step 0: Establish Connection

Ensure a working `exapump` profile before giving terminal workflows that use
`exapump upload`:

1. If the user mentions a specific profile name, test it with `exapump sql --profile <name> "SELECT 1"`.
2. Otherwise, test the default profile with `exapump sql "SELECT 1"`.
3. If the check fails, run `exapump profile list`.
4. If profiles exist, ask which one to use and retry the connectivity check.
5. If no profiles exist, tell the user to run `exapump profile add default` and retry.
6. Never read or reference the exapump configuration file.

Trigger when the user mentions **IMPORT**, **IMPORT INTO**, **upload CSV**, **upload Parquet**, **local file load**, **exapump upload**, **S3 import**, **Azure Blob import**, **GCS import**, **CREATE CONNECTION**, or **Parquet import**.

## Routing Algorithm

1. **Local files on the user machine**
   - Trigger phrases: `upload csv`, `upload parquet`, `exapump upload`, `from local`
   - Load: `references/import.md`

2. **Remote or cloud files reachable by Exasol**
   - Trigger phrases: `IMPORT`, `IMPORT INTO`, `S3`, `Azure Blob`, `GCS`, `FTP`, `HTTP`, `CREATE CONNECTION`
   - Load: `references/import.md`

3. **Parquet-specific behavior**
   - Trigger phrases: `parquet`, `SOURCE COLUMN NAMES`, `SkipCols`, `MaxConnections`, `MaxConcurrentReads`
   - Load: `references/import.md`

## Notes

- Use this skill only for direct data movement into Exasol.
- Use **exasol-database** for general SQL, schema inspection, table design, and native `EXPORT` workflows.
- Use **exasol-extension-catalog** when the user is asking for extension-based object-storage loading workflows or federated-read alternatives rather than direct `IMPORT`.
