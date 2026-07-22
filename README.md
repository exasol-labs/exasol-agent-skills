<div align="center">

<img src="assets/logo.svg" alt="Exasol Agent Skills logo" width="180">

# Exasol Agent Skills

[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://code.claude.com/docs/en/plugins)
[![OpenAI Codex](https://img.shields.io/badge/OpenAI_Codex-skill-orange.svg)](https://openai.com/codex)
[![Exasol](https://img.shields.io/badge/Exasol-database-green.svg)](https://exasol.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Agent skills for [Exasol](https://exasol.com) — gives Claude Code and OpenAI Codex expertise in exapump, Exasol SQL, UDFs, and cloud data loading.

</div>

---

## Get Started

**One-line install:**

```bash
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/install.sh | sh
```

The installer prompts you to choose which agents to install for (Claude Code, OpenAI Codex, or both). When piped non-interactively, it installs for both by default. Set `AGENT` to install for a specific agent:

```bash
export AGENT=claude
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/install.sh | sh
```

```bash
export AGENT=codex
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/install.sh | sh
```

Running the installer again updates to the latest version.

<details>
<summary>Manual install</summary>

**Claude Code:**

```bash
claude plugin marketplace add exasol-labs/exasol-agent-skills
claude plugin install exasol@exasol-skills
```

**OpenAI Codex:**

```bash
npx skills add exasol-labs/exasol-agent-skills --agent codex
```

</details>

---

## What You Get

### Unified Exasol Router

Use one entry point for Exasol work:

```
/exasol <anything Exasol-related>
```

The router chooses the right specialized guidance for SQL, data loading, BucketFS, UDFs, Script Language Containers, extension/integration selection, and setup tasks.

See [`plugins/exasol/skills/exasol/SKILL.md`](plugins/exasol/skills/exasol/SKILL.md) and [`plugins/exasol/commands/exasol.md`](plugins/exasol/commands/exasol.md) for details.

### Exasol Database Skill

Work with Exasol databases — run queries, inspect schemas, design tables, and get help with Exasol-specific SQL quirks outside the dedicated import and export skills.

See [`plugins/exasol/skills/exasol-database/SKILL.md`](plugins/exasol/skills/exasol-database/SKILL.md) for details.

### Exasol Import Skill

Use Exasol IMPORT SQL plus exapump local file upload workflows for moving data into Exasol. For writing data out of Exasol, use the Exasol Export skill.

See [`plugins/exasol/skills/exasol-import/SKILL.md`](plugins/exasol/skills/exasol-import/SKILL.md) for details.

### Exasol Export Skill

Use Exasol EXPORT SQL plus exapump local file export workflows for moving data out of Exasol.

See [`plugins/exasol/skills/exasol-export/SKILL.md`](plugins/exasol/skills/exasol-export/SKILL.md) for details.

### Exasol Cloud Storage Extension Skill

Use the Exasol Cloud Storage Extension when the task is an extension-based object-storage import/export workflow rather than direct native IMPORT or EXPORT.

See [`plugins/exasol/skills/exasol-cloud-storage-extension/SKILL.md`](plugins/exasol/skills/exasol-cloud-storage-extension/SKILL.md) for details.

### Exasol JDBC Virtual Schemas Skill

Use Exasol JDBC-based virtual schemas for federated read-only queries against external databases without copying the source data into Exasol.

See [`plugins/exasol/skills/exasol-jdbc-virtual-schemas/SKILL.md`](plugins/exasol/skills/exasol-jdbc-virtual-schemas/SKILL.md) for details.

### Exasol Document Virtual Schemas Skill

Use Exasol document-file virtual schemas for federated read-only access to object and file storage (S3, Google Cloud Storage, Azure Blob, Azure Data Lake Storage Gen2).

See [`plugins/exasol/skills/exasol-document-virtual-schemas/SKILL.md`](plugins/exasol/skills/exasol-document-virtual-schemas/SKILL.md) for details.

### Exasol Virtual Schema Adapter Development Skill

Build, package, validate, and debug custom Exasol virtual schema adapters when an existing JDBC or document-file virtual schema adapter is not enough.

See [`plugins/exasol/skills/exasol-virtual-schema-adapter-development/SKILL.md`](plugins/exasol/skills/exasol-virtual-schema-adapter-development/SKILL.md) for details.

### Exasol Extension Catalog Skill

Choose the right Exasol tool, extension, connector, integration, or architecture pattern for deployment, data loading, exploration, AI/ML enrichment, BI/API surfaces, governance, and scale.

See [`plugins/exasol/skills/exasol-extension-catalog/SKILL.md`](plugins/exasol/skills/exasol-extension-catalog/SKILL.md) for details.

### Exasol UDF Skill

Build User Defined Functions in Python, Java, Lua, or R, and package them into deployable Script Language Containers.

See [`plugins/exasol/skills/exasol-udfs/SKILL.md`](plugins/exasol/skills/exasol-udfs/SKILL.md) for details.

### BucketFS Skill

Manage files in Exasol's distributed file system — list, upload, download, and delete files that your UDFs and scripts can access.

See [`plugins/exasol/skills/exasol-bucketfs/SKILL.md`](plugins/exasol/skills/exasol-bucketfs/SKILL.md) for details.

### Exasol AI Setup Skill

Set up notebook-connector configuration via the `scs` CLI or the `Secrets` Python API before using AI-related workflows.

See [`plugins/exasol/skills/exasol-ai-setup/SKILL.md`](plugins/exasol/skills/exasol-ai-setup/SKILL.md) for details.

### Exasol ITDE Skill

Run and manage notebook-connector's local Docker-based Exasol development environment.

See [`plugins/exasol/skills/exasol-itde/SKILL.md`](plugins/exasol/skills/exasol-itde/SKILL.md) for details.

### Exasol Notebook Connector Connections Skill

Use notebook-connector's Python helpers for Exasol, BucketFS, SQLAlchemy, and Ibis connections.

See [`plugins/exasol/skills/exasol-notebook-connections/SKILL.md`](plugins/exasol/skills/exasol-notebook-connections/SKILL.md) for details.

### Exasol Text AI Extension Skill

Deploy and use the notebook-connector-based Text AI Extension for named-entity recognition, zero-shot classification, feature extraction, and pipeline-based text workflows inside Exasol.

See [`plugins/exasol/skills/exasol-text-ai/SKILL.md`](plugins/exasol/skills/exasol-text-ai/SKILL.md) for details.

### Exasol Transformers Extension Skill

Deploy and use the notebook-connector-based Transformers Extension for NLP inference inside Exasol, including workflows that use Hugging Face models.

See [`plugins/exasol/skills/exasol-transformers/SKILL.md`](plugins/exasol/skills/exasol-transformers/SKILL.md) for details.

### Exasol Personal Setup Skill

Step-by-step guided setup of your own Exasol database on AWS — from account creation and IAM configuration to deployment, data loading, and exploration. No prior AWS or Exasol experience required.

Triggers on: "set up Exasol", "Exasol Personal", "deploy Exasol", "install Exasol on AWS"

See [`plugins/exasol/skills/setup-personal/SKILL.md`](plugins/exasol/skills/setup-personal/SKILL.md) for details.

### `/exasol` Slash Command <sup>Claude Code only</sup>

Run SQL or describe any Exasol task directly:

```
/exasol SELECT * FROM my_table
/exasol upload sales.csv to analytics.sales
/exasol export users to parquet
/exasol build a custom virtual schema adapter for a new JDBC dialect
/exasol list BucketFS files under models/
/exasol which connector should I use for Databricks?
/exasol initialize the Text AI Extension for notebook-connector
/exasol write a Python UDF
/exasol set up Exasol Personal on AWS
```

---

## Contributing Skills

Keep the user interface simple: users should type `/exasol <task>` or ask naturally. Do not require users to know sub-skill names.

When adding a new Exasol capability:

1. Add a focused skill under `plugins/exasol/skills/<skill-name>/SKILL.md`.
2. Put detailed docs in `references/` and runnable templates in `scripts/` when useful.
3. Add the new route to `plugins/exasol/skills/exasol/SKILL.md`.
4. Mirror the route in `plugins/exasol/commands/exasol.md`.
5. Update this README only with user-facing capability text, not internal routing details.
6. Bump both manifest versions and add a CHANGELOG entry.

Avoid adding new slash commands unless there is a strong backwards-compatibility reason. Prefer `/exasol bucketfs ...` over introducing a separate command for each domain.

## Prerequisites

| Requirement | Needed for |
|-------------|------------|
| [exapump](https://github.com/exasol-labs/exapump) CLI | Both agents |
| Access to an Exasol database | Both agents |
| [Claude CLI](https://docs.anthropic.com/en/docs/claude-code/overview) | Claude Code |
| [Node.js / npx](https://nodejs.org) | OpenAI Codex |

---

## License

Community-supported. Licensed under [MIT](LICENSE).

---

<div align="center">

Made with ❤️ as part of [Exasol Labs 🧪](https://github.com/exasol-labs/).

</div>
