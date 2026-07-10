---
name: exasol-document-virtual-schemas
description: "Use Exasol document-file virtual schemas for federated read-only access to object and file storage. Covers document-file adapter family selection, CREATE VIRTUAL SCHEMA usage, refresh workflows, and query-side troubleshooting."
---

# Exasol Document Virtual Schemas Skill

Trigger when the user mentions **document files virtual schema**, **S3 document files**, **BucketFS document files**, **Google Cloud Storage document files**, **Azure Blob document files**, **Azure Data Lake Storage Gen2 document files**, **EXPLAIN VIRTUAL**, or **ALTER VIRTUAL SCHEMA**.

## Routing Algorithm

1. **Create and query a virtual schema**
   - Trigger phrases: `CREATE VIRTUAL SCHEMA`, `document files virtual schema`, `connection name`, `query object storage`
   - Load: `references/document-virtual-schemas.md`

2. **Refresh, debugging, and troubleshooting**
   - Trigger phrases: `EXPLAIN VIRTUAL`, `REFRESH`, `partial refresh`, `connection validation`, `pushdown`
   - Load: `references/document-virtual-schemas.md`

3. **Choose the right document-file adapter family**
   - Trigger phrases: `document virtual schema`, `S3 document files`, `BucketFS document files`, `Google Cloud Storage document files`, `Azure Blob document files`, `Azure Data Lake Storage Gen2 document files`
   - Load: `references/document-virtual-schemas.md`

## Notes

- Use this skill for federated read-only access through virtual schemas.
- Use **exasol-import** or **exasol-cloud-storage-extension** when the user wants to copy data into Exasol instead of querying it in place.
- Use **exasol-jdbc-virtual-schemas** when the source is a JDBC database rather than object or file storage.
- Use **exasol-virtual-schema-adapter-development** when the user needs custom adapter build or remote debugging work.
- Use **exasol-bucketfs** if the task is specifically about uploading the adapter JAR into BucketFS.
