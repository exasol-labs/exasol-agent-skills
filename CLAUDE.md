# Exasol Skills Marketplace

This repo is a Claude Code plugin marketplace containing skills for working with Exasol databases.

## Repository Structure

```
exasol-skills/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest (discovery entry point)
├── plugins/
│   └── exasol/                   # Exasol database plugin
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin metadata
│       ├── skills/
│       │   └── exasol-database/  # Main skill
│       │       ├── SKILL.md      # Skill definition (triggers, content)
│       │       └── references/   # Detailed reference docs (progressive disclosure)
│       │           ├── exapump-reference.md
│       │           └── exasol-sql.md
│       └── commands/
│           └── exasol.md         # /exasol slash command
├── install.sh                    # Curl-pipeable installer (idempotent)
├── Dockerfile.test               # Docker image for installer CI tests
├── test/
│   ├── mock-claude.sh            # Mock claude CLI for testing
│   └── test-installer.sh         # Test runner (fresh/idempotent/update)
├── .github/workflows/ci.yml     # CI: validate manifests + test installer
├── CLAUDE.md                     # This file
├── README.md
└── LICENSE
```

## How Plugins Work

- **Marketplace manifest** (`.claude-plugin/marketplace.json`): Lists all available plugins
- **Plugin metadata** (`plugins/<name>/.claude-plugin/plugin.json`): Describes a plugin's skills and commands
- **Skills** (`SKILL.md`): Auto-triggered context injected based on keyword matching in user messages
- **Commands** (`commands/<name>.md`): Slash commands users invoke explicitly with `/name`
- **References**: Supplementary docs loaded only when the skill needs deeper detail

## Adding a New Plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with metadata
2. Add skills in `plugins/<name>/skills/<skill-name>/SKILL.md`
3. Add commands in `plugins/<name>/commands/<command>.md`
4. Register the plugin in `.claude-plugin/marketplace.json`

## Installation

End users install via the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exasol-agent-skills/main/install.sh | sh
```

`install.sh` is idempotent: it adds the marketplace and installs the plugin on first run, and updates both on subsequent runs. It requires only the `claude` CLI and POSIX tools (no `jq`).

## Local Development

To test this marketplace locally:

```bash
claude plugin marketplace add ./path/to/exasol-agent-skills
claude plugin install exasol@exasol-skills
```

Validate manifests with:

```bash
claude plugin validate .
claude plugin validate ./plugins/exasol
```
