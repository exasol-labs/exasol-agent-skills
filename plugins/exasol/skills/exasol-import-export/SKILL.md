---
name: exasol-import-export
description: "Use Exasol IMPORT and EXPORT SQL plus exapump local file workflows for moving data into or out of Exasol. Covers CSV, FBV, Parquet, connection objects, cloud credential patterns, reject handling, and staging-based import workflows."
---

# Exasol Import Export Skill

Trigger when the user mentions **IMPORT INTO**, **EXPORT INTO**, **upload CSV**, **upload Parquet**, **export table**, **local file load**, **S3 import**, **Azure Blob import**, **GCS import**, **CREATE CONNECTION**, or **Parquet import**.

## Routing Algorithm

1. **Local files on the user machine**
   - Trigger phrases: `upload csv`, `upload parquet`, `export local file`, `from local`, `into local`
   - Load: `references/import-export.md`

2. **Remote or cloud files reachable by Exasol**
   - Trigger phrases: `IMPORT INTO`, `EXPORT INTO`, `S3`, `Azure Blob`, `GCS`, `FTP`, `HTTP`, `CREATE CONNECTION`
   - Load: `references/import-export.md`

3. **Parquet-specific behavior**
   - Trigger phrases: `parquet`, `SOURCE COLUMN NAMES`, `SkipCols`, `MaxConnections`, `MaxConcurrentReads`
   - Load: `references/import-export.md`

## Notes

- Use this skill for direct data movement into or out of Exasol.
- Use **exasol-database** for general SQL, schema inspection, and table design outside the import/export workflow itself.
- Use **exasol-data-loading** when the user is asking for extension-based or connector-based loading workflows rather than direct IMPORT/EXPORT behavior.
