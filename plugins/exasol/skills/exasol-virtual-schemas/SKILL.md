---
name: exasol-virtual-schemas
description: "Use Exasol virtual schemas for federated read-only access to external systems and document-file adapters. Covers adapter selection, EXPLAIN VIRTUAL, refresh workflows, troubleshooting, generic JDBC fallback, document-based virtual schemas, and custom adapter build and setup patterns."
---

# Exasol Virtual Schemas Skill

Trigger when the user mentions **virtual schema**, **adapter script**, **EXPLAIN VIRTUAL**, **ALTER VIRTUAL SCHEMA**, **generic JDBC**, **document files virtual schema**, **remote debugging for virtual schemas**, or **build a custom virtual schema adapter**.

## Routing Algorithm

1. **Create and query a virtual schema**
   - Trigger phrases: `CREATE VIRTUAL SCHEMA`, `adapter script`, `connection name`, `query external database`
   - Load: `references/virtual-schemas.md`

2. **Refresh, debugging, and troubleshooting**
   - Trigger phrases: `EXPLAIN VIRTUAL`, `REFRESH`, `partial refresh`, `connection validation`, `pushdown`, `remote debugging`
   - Load: `references/virtual-schemas.md`

3. **Choose the right adapter family**
   - Trigger phrases: `supported dialect`, `generic JDBC`, `document virtual schema`, `S3 document files`, `BucketFS document files`
   - Load: `references/virtual-schemas.md`

4. **Build or customize an adapter**
   - Trigger phrases: `custom adapter`, `build virtual schema`, `new SQL dialect`, `virtual-schema-common-jdbc`
   - Load: `references/adapter-development.md`

## Notes

- Use this skill for federated read-only access through virtual schemas.
- Use **exasol-import-export** or **exasol-data-loading** when the user wants to copy data into Exasol instead of querying it in place.
- Use **exasol-bucketfs** if the task is specifically about uploading the adapter JAR into BucketFS.
