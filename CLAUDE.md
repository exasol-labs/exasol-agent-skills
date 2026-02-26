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
│       │   ├── exasol-database/  # Database interaction skill
│       │   │   ├── SKILL.md      # Skill definition (triggers, routing)
│       │   │   └── references/   # Detailed reference docs (progressive disclosure)
│       │   │       ├── analytics-qualify.md
│       │   │       ├── exapump-reference.md
│       │   │       ├── exasol-sql.md
│       │   │       ├── import-export.md
│       │   │       ├── query-profiling.md
│       │   │       ├── table-design.md
│       │   │       └── virtual-schemas.md
│       │   └── exasol-udfs/      # UDF development skill
│       │       ├── SKILL.md
│       │       └── references/
│       │           ├── slc-reference.md
│       │           ├── udf-java-lua.md
│       │           └── udf-python.md
│       └── commands/
│           └── exasol.md         # /exasol slash command
├── install.sh                    # Curl-pipeable installer (idempotent)
├── Dockerfile.test               # Docker image for installer CI tests
├── test/
│   ├── mock-claude.sh            # Mock claude CLI for testing
│   ├── mock-curl.sh              # Mock curl for testing
│   ├── mock-exapump.sh           # Mock exapump for testing
│   └── test-installer.sh         # Test runner (fresh/idempotent/update)
├── .github/workflows/ci.yml     # CI: validate manifests + test installer + release
├── CHANGELOG.md
├── CLAUDE.md                     # This file
├── README.md
└── LICENSE
```

## How Plugins Work

- **Marketplace manifest** (`.claude-plugin/marketplace.json`): Lists all available plugins with version
- **Plugin metadata** (`plugins/<name>/.claude-plugin/plugin.json`): Describes a plugin's skills and commands
- **Skills** (`SKILL.md`): Auto-triggered context injected based on keyword matching in user messages
- **Commands** (`commands/<name>.md`): Slash commands users invoke explicitly with `/name`
- **References**: Supplementary docs loaded on demand by the skill's routing algorithm

## How the Agent Uses Skills

When a user mentions Exasol-related topics, Claude Code:

1. **Triggers** the skill — `SKILL.md` front-matter keywords match the user's message
2. **Establishes connection** — tests `exapump sql "SELECT 1"` to verify database access
3. **Routes to references** — the routing algorithm in `SKILL.md` loads only the reference files relevant to the task (e.g., `import-export.md` for data loading, `exasol-sql.md` for SQL queries)
4. **Executes** — uses exapump CLI commands and Exasol SQL guided by the loaded references

The routing is progressive: a simple SQL query loads only `exapump-reference.md` + `exasol-sql.md`, while an ETL pipeline task loads `import-export.md` as well. This keeps context lean.

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

`install.sh` is idempotent: it adds the marketplace and installs the plugin on first run, and updates both on subsequent runs. It reads the version from `marketplace.json` at runtime (no hardcoded version). It requires only the `claude` CLI and POSIX tools (no `jq`).

## Local Development

To test this marketplace locally:

```bash
claude plugin marketplace add ./path/to/exasol-agent-skills
claude plugin install exasol@exasol-skills
```

After making changes to skill or reference files, update the plugin to pick them up:

```bash
claude plugin update exasol --scope user
```

Then start a new Claude Code session to load the updated skill.

## Testing

### Validate Manifests

```bash
claude plugin validate .
claude plugin validate ./plugins/exasol
```

### Installer Tests (Docker)

The installer is tested with mocked CLIs (`claude`, `curl`, `exapump`) in a Docker container. Three scenarios cover the main install paths:

```bash
# Build the test image
docker build -f Dockerfile.test -t installer-test .

# Run all three scenarios
docker run --rm -e SCENARIO=fresh      installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=idempotent installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=update     installer-test sh test/test-installer.sh
```

| Scenario | What it tests |
|----------|---------------|
| `fresh` | First-time install: no exapump, no plugin, no marketplace |
| `idempotent` | Re-run when everything is already installed and up to date |
| `update` | Upgrade from an older plugin + exapump version |

### CI Pipeline

CI (`.github/workflows/ci.yml`) runs on every push to `main` and on PRs:
- **validate-plugin**: Checks JSON validity and version consistency between `marketplace.json` and `plugin.json`
- **test-installer**: Runs all three Docker installer scenarios
- **release** (tags only): On `v*` tags, creates a GitHub release with auto-generated notes

## Releasing

1. Update the version in both manifests (must match):
   - `.claude-plugin/marketplace.json` → `metadata.version`
   - `plugins/exasol/.claude-plugin/plugin.json` → `version`
2. Update `CHANGELOG.md` — rename `Unreleased` to the new version
3. Commit: `chore: release vX.Y.Z`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push --follow-tags`

The CI release job creates a GitHub release automatically when the tag is pushed.
