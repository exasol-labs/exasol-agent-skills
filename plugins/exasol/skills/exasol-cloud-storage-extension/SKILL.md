---
name: exasol-cloud-storage-extension
description: "Use Exasol Cloud Storage Extension workflows for loading object-storage files into Exasol through the extension-based read path. Covers object storage, file-reader behavior, and routing away from native IMPORT when the extension path is the right fit."
---

# Exasol Cloud Storage Extension Skill

Trigger when the user mentions **Cloud Storage Extension**, **load from object storage**, **read parquet from bucket**, **Avro**, **ORC**, or **extension-based file reader**.

## Routing Algorithm

1. **Object storage and file-reader extension workflows**
   - Trigger phrases: `Cloud Storage Extension`, `object storage`, `ORC`, `Avro`, `read parquet from bucket`
   - Load: `references/cloud-storage-extension.md`

## Notes

- Use this skill when the user needs the Cloud Storage Extension path rather than direct native `IMPORT`.
- Use **exasol-import** for direct local-file and native SQL import behavior.
- Use **exasol-extension-catalog** when the user wants federated read-only access instead of loading data into Exasol.
