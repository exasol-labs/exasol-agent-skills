# Exasol Skills Marketplace

A Claude Code plugin marketplace for [Exasol database](https://exasol.com).

## Get started

Add the marketplace and the plugin

```bash
claude plugin add marketplace https://github.com/exasol-labs/exasol-skills
claude plugin add exasol
```

That's it. The skill and `/exasol` slash command are now available in your Claude Code sessions.

## What You Get

### Exasol Database Skill

Automatically activates when you mention Exasol, exapump, or related topics. Provides:

- **exapump CLI guidance** — upload, query, export, interactive sessions
- **Exasol SQL expertise** — data type quirks, reserved keywords, constraint limitations
- **Error diagnosis** — identifies Exasol-specific issues (identifier casing, reserved words, etc.)
- **Cloud data loading** — S3, Azure Blob, GCS via SQL IMPORT

### `/exasol` Slash Command

Run SQL or describe tasks directly:

```
/exasol SELECT * FROM my_table
/exasol upload sales.csv to analytics.sales
/exasol export users to parquet
```

## Prerequisites

- [exapump](https://github.com/exasol-labs/exapump) CLI installed
- Access to an Exasol database instance

## License

[MIT](LICENSE)