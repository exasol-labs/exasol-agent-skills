---
name: exasol-import
description: "Use Exasol IMPORT SQL plus exapump local file upload workflows for moving data into Exasol. Covers CSV, FBV, Parquet, connection objects, cloud credential patterns, reject handling, and staging-based import workflows."
---

# Exasol Import Skill

This skill covers only workflows that move data into Exasol.

Trigger when the user mentions **IMPORT**, **IMPORT INTO**, **upload CSV**, **upload Parquet**, **local file load**, **S3 import**, **Azure Blob import**, **GCS import**, **CREATE CONNECTION**, or **Parquet import**.

## Routing Algorithm

1. **Local files on the user machine**
   - Trigger phrases: `upload csv`, `upload parquet`, `from local`
   - Load: `references/import.md`

2. **Remote or cloud files reachable by Exasol**
   - Trigger phrases: `IMPORT`, `IMPORT INTO`, `S3`, `Azure Blob`, `GCS`, `FTP`, `HTTP`, `CREATE CONNECTION`
   - Load: `references/import.md`

3. **Parquet-specific behavior**
   - Trigger phrases: `parquet`, `SOURCE COLUMN NAMES`, `SkipCols`, `MaxConnections`, `MaxConcurrentReads`
   - Load: `references/import.md`

## Notes

- Use this skill only for direct data movement into Exasol.
- Use **exasol-database** for general SQL, schema inspection, table design, and native `EXPORT` workflows outside direct import behavior.
- Use **exasol-extension-catalog** when the user is asking for extension-based object-storage loading workflows or federated-read alternatives rather than direct `IMPORT`.
