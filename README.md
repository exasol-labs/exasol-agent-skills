# Exasol Agent Skills

[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://code.claude.com/docs/en/plugins)
[![OpenAI Codex](https://img.shields.io/badge/OpenAI_Codex-skill-orange.svg)](https://openai.com/codex)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Skills for Claude Code and OpenAI Codex that provide focused Exasol guidance.
Use `/exasol <task>` or ask naturally.

## Install and update

```bash
curl -fsSL --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/install.sh | sh
```

The installer prompts for Claude Code, Codex, or both. For automation, set
`AGENT=claude`, `AGENT=codex`, or `AGENT=both`. A non-interactive invocation
defaults to both agents. Rerunning it updates the selected integrations.

For Codex, interactive runs open the skill picker. Select the shared `exasol`
router plus any specialized skills you want. Truly non-interactive runs install
all skills; set `CODEX_SKILLS=all` to request that behavior explicitly.

exapump is optional and is never installed or updated silently. Interactive
runs ask first. For an explicit non-interactive installation or update, set
`INSTALL_EXAPUMP=yes`; otherwise the installer skips it.

```bash
curl -fsSL --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/install.sh \
  | AGENT=both CODEX_SKILLS=all INSTALL_EXAPUMP=yes sh
```

Manual installation:

```bash
# Claude Code
claude plugin marketplace add exasol-labs/exasol-agent-skills
claude plugin install exasol@exasol-skills

# OpenAI Codex
npx --yes skills@1.5.22 add exasol-labs/exasol-agent-skills \
  --agent codex --global
```

Manual update:

```bash
# Claude Code
claude plugin marketplace update exasol-skills
claude plugin update exasol@exasol-skills --scope user

# OpenAI Codex
npx --yes skills@1.5.22 add exasol-labs/exasol-agent-skills \
  --agent codex --global
```

## Features

- SQL, schema, table-design, reserved-keyword, and exapump guidance.
- Native `IMPORT` and `EXPORT`, local file movement, and Cloud Storage Extension workflows.
- JDBC and document-file virtual schemas, plus custom adapter development.
- Extension and integration selection for deployment, loading, enrichment, BI/API, governance, and scale.
- UDFs, Script Language Containers, BucketFS, distributed ML, and GPU workflows.
- Notebook-connector setup, ITDE lifecycle, Python connection helpers, Text AI, and Transformers.
- Exasol Personal setup for local macOS and AWS, Azure, Exoscale, or STACKIT deployments.

The complete skill catalog is available under
[`plugins/exasol/skills/`](plugins/exasol/skills/).

## Usage examples

```text
/exasol SELECT * FROM my_table LIMIT 10
/exasol upload sales.csv to analytics.sales
/exasol export users to parquet
/exasol create a PostgreSQL JDBC virtual schema
/exasol build a custom virtual schema adapter for a new JDBC dialect
/exasol list BucketFS files under models/
/exasol initialize the Text AI Extension for notebook-connector
/exasol write a Python UDF
/exasol set up Exasol Personal on AWS
```

## Requirements

| Requirement | Used by |
| --- | --- |
| [exapump](https://github.com/exasol-labs/exapump) | Database and file-movement workflows |
| Access to an Exasol database | Database workflows |
| [Claude CLI](https://docs.anthropic.com/en/docs/claude-code/overview) | Claude Code integration |
| [Node.js](https://nodejs.org) and `npx` | Codex integration |

## Contributing

Add a focused `SKILL.md` under `plugins/exasol/skills/<skill-name>/`, put
long-form material in `references/`, update the user-visible feature list when
the catalog changes, bump both manifest versions, and add a changelog entry.
Keep local Markdown links valid.

## License

Licensed under [MIT](LICENSE).
