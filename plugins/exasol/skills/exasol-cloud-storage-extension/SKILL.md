---
name: exasol-cloud-storage-extension
description: "Use Exasol Cloud Storage Extension workflows for moving structured object-storage files through extension UDFs. Covers setup prerequisites, fixed UDF entrypoints, supported import/export formats, connection-object credential patterns, and routing away from native IMPORT or EXPORT when the extension path is the right fit."
---

# Exasol Cloud Storage Extension Skill

Trigger when the user mentions **Cloud Storage Extension**, **extension-based object-storage loading**, **extension-based Parquet reader**, **Avro through Cloud Storage Extension**, **ORC through Cloud Storage Extension**, **Delta through Cloud Storage Extension**, **extension-based Parquet export**, or **extension-based file reader**.

## Routing Algorithm

1. **Object storage and file-reader extension workflows**
   - Trigger phrases: `Cloud Storage Extension`, `extension-based object-storage loading`, `extension-based Parquet reader`, `ORC through Cloud Storage Extension`, `Avro through Cloud Storage Extension`, `Delta through Cloud Storage Extension`, `extension-based Parquet export`
   - Load: `references/cloud-storage-extension.md`

## Notes

- Use this skill when the user needs the Cloud Storage Extension UDF path rather than direct native `IMPORT` or `EXPORT`.
- Use **exasol-import** for direct local-file and native SQL import behavior.
- Use **exasol-export** for direct native SQL export behavior and local `exapump export`.
- Use **exasol-bucketfs** when the user needs to upload, list, or remove the extension JAR in BucketFS.
- Use **exasol-extension-catalog** when the user wants federated read-only access instead of copying data.
