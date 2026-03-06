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

Work with Exasol databases — run queries, load and export data, handle cloud sources, and get help with Exasol-specific SQL quirks.

See [`plugins/exasol/skills/exasol-database/SKILL.md`](plugins/exasol/skills/exasol-database/SKILL.md) for details.

### Exasol UDF Skill

Build User Defined Functions in Python, Java, Lua, or R, and package them into deployable Script Language Containers.

See [`plugins/exasol/skills/exasol-udfs/SKILL.md`](plugins/exasol/skills/exasol-udfs/SKILL.md) for details.

### BucketFS Skill

Manage files in Exasol's distributed file system — list, upload, download, and delete files that your UDFs and scripts can access.

See [`plugins/exasol/skills/exasol-bucketfs/SKILL.md`](plugins/exasol/skills/exasol-bucketfs/SKILL.md) for details.

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
