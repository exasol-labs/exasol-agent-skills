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
│       ├── commands/
│       │   └── exasol.md         # /exasol slash command
│       └── README.md
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

## Local Development

To register this marketplace locally for testing, add to your Claude Code settings:

```json
{
  "plugins": {
    "marketplaces": ["/path/to/exasol-skills"]
  }
}
```
