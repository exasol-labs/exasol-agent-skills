---
name: exasol-export
description: "Use Exasol EXPORT SQL plus exapump local file export workflows for moving data out of Exasol. Covers native CSV/FBV export, local CSV/Parquet exports with exapump, connection objects, reject limits, and export credential patterns."
---

# Exasol Export Skill

This skill covers only workflows that move data out of Exasol.

## Step 0: Establish Connection

Ensure a working `exapump` profile before giving terminal workflows that use
`exapump export`:

1. If the user mentions a specific profile name, test it with `exapump sql --profile <name> "SELECT 1"`; always place `--profile` after the subcommand.
2. Otherwise, test the default profile with `exapump sql "SELECT 1"`.
3. If the check fails, run `exapump profile list`.
4. If profiles exist, ask which one to use and retry with `exapump sql --profile <name> "SELECT 1"`; keep `--profile` after the subcommand.
5. If a non-default profile is selected, include the same `--profile <name>` after the subcommand on subsequent `exapump` commands, such as `exapump export --profile <name> --table <schema.table> --output <file> --format <format>`.
6. If no profiles exist, tell the user to run `exapump profile add default` and retry.
7. Never read or reference the exapump configuration file.

Trigger when the user mentions **EXPORT**, **EXPORT INTO**, **export table**, **export local file**, **exapump export**, **export CSV**, **export Parquet**, **export to S3**, **export to Azure Blob**, **export to GCS**, **export to FTP**, **export to SFTP**, **export to HTTP**, **export to HTTPS**, **REJECT LIMIT** with export intent, or **CREATE CONNECTION** together with export target setup intent.

## Routing Algorithm

1. **Local files on the user machine**
   - Trigger phrases: `export local file`, `into local`, `to local`, `exapump export`
   - Load: `references/export.md`

2. **Remote or cloud files reachable by Exasol**
   - Trigger phrases: `EXPORT`, `EXPORT INTO`, `S3`, `Azure Blob`, `GCS`, `FTP`, `SFTP`, `HTTP`, `HTTPS`, `REJECT LIMIT`, `CREATE CONNECTION` with export target setup intent
   - Load: `references/export.md`

3. **Connection-object export setup**
   - Trigger phrases: `CREATE CONNECTION` with export target setup intent, `ALTER CONNECTION`, `temporary credentials`, `SESSION TOKEN`
   - Load: `references/export.md`

4. **Script-based export target**
   - Trigger phrases: `EXPORT INTO SCRIPT`, `export script`, `custom export script`
   - Load: `references/export.md`

## Notes

- Use this skill for direct data movement out of Exasol.
- Use **exasol-import** for native `IMPORT`, local upload workflows, Parquet import, reject handling, and staging-based loading into Exasol.
- Use **exasol-cloud-storage-extension** for explicit extension-based Parquet export. Use **exasol-extension-catalog** only when the user is still choosing among native export, extension, connector, or integration families.
