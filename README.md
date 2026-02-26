<div align="center">

<img src="assets/logo.svg" alt="Exasol Agent Skills logo" width="200">

# Exasol Agent Skills

[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://code.claude.com/docs/en/plugins)
[![Exasol](https://img.shields.io/badge/Exasol-database-green.svg)](https://exasol.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

Claude Code plugin marketplace for [Exasol](https://exasol.com) — gives Claude expertise in exapump, Exasol SQL, and cloud data loading.

</div>

---

## Get Started

**One-line install:**

```bash
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/install.sh | sh
```

Running this again updates to the latest version.

<details>
<summary>Manual install</summary>

```bash
claude plugin marketplace add exasol-labs/exasol-agent-skills
claude plugin install exasol@exasol-skills
```

</details>

That's it. The skill and `/exasol` slash command are now available in your Claude Code sessions.

---

## What You Get

### Exasol Database Skill

Automatically activates when you mention Exasol, exapump, or related topics. Provides:

- **exapump CLI guidance** — upload, query, export, interactive sessions
- **Exasol SQL expertise** — data types, reserved keywords, constraint limitations
- **Error diagnosis** — identifies Exasol-specific issues (identifier casing, reserved words, etc.)
- **Cloud data loading** — S3, Azure Blob, GCS via SQL IMPORT

### `/exasol` Slash Command

Run SQL or describe tasks directly:

```
/exasol SELECT * FROM my_table
/exasol upload sales.csv to analytics.sales
/exasol export users to parquet
```

---

## Prerequisites

- [exapump](https://github.com/exasol-labs/exapump) CLI installed
- Access to an Exasol database instance

---

## License

Community-supported. Licensed under [MIT](LICENSE).

---

<div align="center">

Made with ❤️ as part of [Exasol Labs 🧪](https://github.com/exasol-labs/).

</div>
