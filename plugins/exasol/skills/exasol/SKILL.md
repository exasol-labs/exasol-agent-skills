---
name: exasol
description: Top-level router for Exasol work. Use for any Exasol database, exapump, SQL, BucketFS, extension, integration, UDF, Script Language Container, or Exasol Personal setup task, then route to the narrowest specialized Exasol skill.
---

# Exasol Router Skill

Use this skill whenever the user asks about Exasol. The user does not need to know internal skill names. Treat `/exasol <task>` and natural-language Exasol requests as the public interface.

This `SKILL.md` is the shared routing source of truth for OpenAI Codex and
Claude Code. Claude's `/exasol` and `/bucketfs` commands delegate to it and must
not copy its rules.

## What This Skill Decides

Each specialized Exasol skill announces its own scope in its front-matter
`description`, and both agents select skills from those descriptions. This
router therefore carries no catalogue of skills and no trigger lists — it is an
arbiter. It holds only what a description structurally cannot express: which
skill wins when two descriptions both fit, what order to resolve prerequisites
in, and the safety and interaction rules that apply to every route.

Choose the narrowest skill whose description matches the request. Apply the
precedence rules below when more than one matches. If several genuinely apply,
load them in dependency order.

## Precedence Rules

**Cloud Storage Extension over native import and export.** When a request
mentions `FROM SCRIPT CLOUD_STORAGE_EXTENSION`, `INTO SCRIPT
CLOUD_STORAGE_EXTENSION`, `CLOUD_STORAGE_EXTENSION.IMPORT_PATH`, or
`CLOUD_STORAGE_EXTENSION.EXPORT_PATH`, prefer
**exasol-cloud-storage-extension** over **exasol-import** or **exasol-export**.

**Object-storage formats that only the extension reads.** When a request
mentions importing `Avro`, `ORC`, or `Delta` from object storage such as S3,
Azure Blob Storage, Azure Data Lake, Google Cloud Storage, HDFS, or Alluxio,
prefer **exasol-cloud-storage-extension** unless the user clearly asks for
native `IMPORT`. Native import handles CSV, FBV, and Parquet; it does not read
those three formats, so a description match on "import from S3" alone routes
the request wrongly.

**Import and export over general database work.** When a request mentions
`IMPORT`, `IMPORT INTO`, or `exapump upload`, prefer **exasol-import** over
**exasol-database** even if the wording also contains generic terms such as
`SQL` or `query`. When it mentions `EXPORT`, `EXPORT INTO`, or `exapump export`,
prefer **exasol-export** the same way. A bare `CREATE CONNECTION` with no
import, export, or object-store file-movement intent belongs to
**exasol-database**.

**Adapter development over adapter use.** When a request mentions custom
virtual schema adapter implementation, source-specific JDBC dialect code,
custom document-file adapter code, `virtual-schema-common-jdbc`, adapter JAR
packaging, custom adapter properties, type mapping, pushdown capabilities,
metadata reader behavior, or adapter-side remote debugging, prefer
**exasol-virtual-schema-adapter-development** over
**exasol-jdbc-virtual-schemas** and **exasol-document-virtual-schemas**.

**Document-file virtual schemas over JDBC virtual schemas.** A virtual schema
over files in object storage — S3, Google Cloud Storage, Azure Blob Storage,
Azure Data Lake Storage Gen2 — is **exasol-document-virtual-schemas**. A
virtual schema over a database source such as PostgreSQL, Oracle, MySQL, SQL
Server, or DB2 is **exasol-jdbc-virtual-schemas**. Do not route a bare
`Virtual Schema` mention to the JDBC skill unless the source is clearly
database-based; ask which source is meant instead.

**Dedicated skills over the catalog.** Route to **exasol-extension-catalog**
only when the primary intent is comparison, discovery, support-status research,
or architecture selection — "which tool should I use", "what are the options
for", "is this supported". A request that names a product, extension, or
integration and asks to execute, configure, or troubleshoot it goes to that
product's dedicated skill, not to the catalog. In particular, Text AI Extension
and `TXAIE` work goes to **exasol-text-ai**, and Transformers Extension work
goes to **exasol-transformers**. Once the catalog has helped the user choose,
hand off.

**Deployment intent is required for Exasol Personal.** Route to
**exasol-setup-personal** only when the user wants to install, deploy, or set up
Exasol itself. A bare cloud-provider or storage token such as `Azure Blob`,
`S3`, or `AWS` is not deployment intent — those belong to the import, export,
and document virtual schema skills.

## Dependency Order

When setup and usage both apply, resolve prerequisites first:

1. Exasol Personal or external database availability
2. Tool, extension, connector, or architecture selection
3. Virtual schema adapter selection when external federation is required
4. Custom virtual schema adapter implementation or packaging when a maintained adapter is not enough
5. Notebook-connector AI setup when required
6. Local Docker database lifecycle or helper-level connectivity validation
7. Extension-specific TXAIE or Transformers workflow
8. SQL, data movement, BucketFS, UDF, SLC, or integration task
9. Distributed ML, data mining, or iterative HPC task (depends on UDF/SLC and BucketFS)

## User Interaction Rules

- Do not ask the user to choose a sub-skill.
- Infer the route from the task.
- If the task is ambiguous, ask one concrete question about the desired outcome, not about internal skill names.
- Prefer `/exasol <task>` in examples.
- Do not expose implementation labels such as **exasol-database** unless the user is contributing to this repo.

## Safety Rules

- Before executing a destructive operation, show the exact target and obtain
  confirmation.
- Never expose credentials, tokens, customer data, or secret configuration in
  commands, output, or generated files.
- Follow any stricter safety or validation rules in the selected specialized
  skill.

## Adding a Skill

A new skill does not need an entry here. It is reached through its own
front-matter `description`, which is why that description is the first thing to
get right — see the skill conventions in `AGENTS.md`. Edit this router only when
the new skill's scope genuinely overlaps an existing one and a description
cannot settle which should win, when it introduces a prerequisite that changes
the dependency order, or when it needs a safety rule that applies beyond itself.
Claude command files must continue delegating to this shared router rather than
restating its rules.
