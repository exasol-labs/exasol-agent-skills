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

### Exasol Database Skill

Automatically activates when you mention Exasol, exapump, or related topics. Provides:

- **exapump CLI guidance** — upload, query, export, interactive sessions
- **Exasol SQL expertise** — data types, reserved keywords, constraint limitations
- **Error diagnosis** — identifies Exasol-specific issues (identifier casing, reserved words, etc.)
- **Cloud data loading** — S3, Azure Blob, GCS via SQL IMPORT

See [`plugins/exasol/skills/exasol-database/SKILL.md`](plugins/exasol/skills/exasol-database/SKILL.md) for the full skill definition and routing logic.

### Exasol UDF Skill

Activates for UDF and Script Language Container topics. Provides:

- **UDF development** — CREATE SCRIPT, SCALAR/SET functions, ExaIterator API
- **Multi-language support** — Python, Java, Lua, R
- **Script Language Containers** — building and deploying custom SLCs with exaslct

See [`plugins/exasol/skills/exasol-udfs/SKILL.md`](plugins/exasol/skills/exasol-udfs/SKILL.md) for the full skill definition.

### `/exasol` Slash Command <sup>Claude Code only</sup>

Run SQL or describe tasks directly:

```
/exasol SELECT * FROM my_table
/exasol upload sales.csv to analytics.sales
/exasol export users to parquet
```

---

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
