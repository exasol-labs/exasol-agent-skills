---
name: exasol-virtual-schema-adapter-development
description: "Build, install, validate, and debug custom Exasol virtual schema adapters. Covers generic JDBC adapter development, JAR packaging, BucketFS deployment, connection-object setup, EXPLAIN VIRTUAL validation, and remote debugging workflows."
---

# Exasol Virtual Schema Adapter Development Skill

Trigger when the user mentions **build a custom virtual schema adapter**, **virtual-schema-common-jdbc**, **remote debugging for virtual schemas**, **new SQL dialect adapter**, or **adapter JAR packaging**.

## Routing Algorithm

1. **Build or customize an adapter**
   - Trigger phrases: `custom adapter`, `build virtual schema`, `new SQL dialect`, `virtual-schema-common-jdbc`, `generic JDBC adapter`
   - Load: `references/adapter-development.md`

2. **Install or update adapter artifacts**
   - Trigger phrases: `adapter JAR`, `driver JAR`, `BucketFS`, `JAVA ADAPTER SCRIPT`, `deploy adapter`
   - Load: `references/adapter-development.md`

3. **Validate and debug adapter behavior**
   - Trigger phrases: `EXPLAIN VIRTUAL`, `connection validation`, `remote debugging`, `pushdown debugging`, `adapter-side issue`
   - Load: `references/adapter-development.md`

## Notes

- Use this skill when the work is about adapter code, packaging, installation, or adapter-side debugging.
- Use **exasol-jdbc-virtual-schemas** or **exasol-document-virtual-schemas** when the user only needs to create, refresh, or query an existing virtual schema.
- Use **exasol-bucketfs** if the task is specifically about generic BucketFS file management outside the adapter deployment flow.
