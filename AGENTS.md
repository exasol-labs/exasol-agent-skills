# AGENTS.md

## What This Repo Is

A skills marketplace for AI coding agents (Claude Code and OpenAI Codex) that gives them expertise in Exasol databases — guided Exasol Personal setup on AWS, exapump CLI, Exasol SQL, UDFs, BucketFS, and cloud data loading.

## Architecture

**Plugin hierarchy:** marketplace → plugin → skills + commands → references

- `.claude-plugin/marketplace.json` — discovery entry point; lists plugins with version
- `plugins/exasol/.claude-plugin/plugin.json` — plugin metadata; version must match marketplace
- `plugins/exasol/skills/exasol/SKILL.md` — top-level router skill; public user model is `/exasol <task>` or natural-language Exasol requests
- `plugins/exasol/skills/*/SKILL.md` — specialized skills with routing algorithms that load only the reference files relevant to the task (progressive disclosure). Skills: `exasol` (top-level router), `setup-personal` (guided AWS deployment), `exasol-database` (SQL/exapump), `exasol-udfs` (UDFs/SLCs), `exasol-bucketfs` (BucketFS)
- `plugins/exasol/commands/exasol.md` — unified `/exasol` slash command router (Claude Code only)
- `plugins/exasol/skills/*/references/*.md` — detailed docs loaded on-demand by SKILL.md routing

**Installer (`install.sh`)** — curl-pipeable, idempotent, POSIX shell (no bash, no jq). Supports both agents:
- Agent selection via `AGENT` env var (`claude`, `codex`, `both`) or interactive prompts; non-interactive defaults to both
- Claude Code path: `claude plugin marketplace add/update` + `claude plugin install/update`
- Codex path: `npx skills add exasol-labs/exasol-agent-skills --agent codex`
- Shared: exapump version check and install/update via GitHub API

## Testing

All installer tests run in Docker with mocked CLIs. **Do not run tests outside Docker** — the mocks replace `claude`, `curl`, `npx`, and `exapump` via PATH injection.

```bash
# Build once
docker build -f Dockerfile.test -t installer-test .

# Run all 5 scenarios
docker run --rm -e SCENARIO=fresh        installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=idempotent   installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=update       installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=fresh-claude installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=fresh-codex  installer-test sh test/test-installer.sh
```

| Scenario | What it tests |
|----------|---------------|
| `fresh` | First-time install: no exapump, both agents |
| `idempotent` | Re-run when everything is already up to date |
| `update` | Upgrade from an older plugin + exapump version |
| `fresh-claude` | Claude Code only (`AGENT=claude`), npx absent |
| `fresh-codex` | Codex only (`AGENT=codex`), claude CLI absent |

Mock files in `test/`: `mock-claude.sh`, `mock-curl.sh`, `mock-exapump.sh`, `mock-npx.sh`. They use `$STATE_DIR` (`/tmp/mock-claude-state`) to track state via files (e.g., `marketplace`, `plugin`, `codex_skills`, `plugin_version`).

Validate manifests (outside Docker):

```bash
claude plugin validate .
claude plugin validate ./plugins/exasol
```

## CI

`.github/workflows/ci.yml` runs on push to `main` and PRs:
1. **validate-plugin** — JSON validity + version consistency between both manifests + version bump check on PRs (must be greater than latest tag)
2. **test-installer** — all 5 Docker scenarios
3. **release** — on `v*` tags, creates GitHub release with auto-generated notes

`.github/workflows/auto-release.yml` runs on PR merge to `main`:
- Creates a git tag and GitHub release from the version in the manifests
- No commits pushed — the PR must already contain the version bump

## Versioning and Releasing

Version lives in two places that **must always match**:
- `.claude-plugin/marketplace.json` → `metadata.version`
- `plugins/exasol/.claude-plugin/plugin.json` → `version`

Releases are automated. When a PR merges to `main`, CI creates a tag and GitHub release from the version in the manifests.

**PR authors must bump the version** in both manifests as part of their PR. CI validates the version is strictly greater than the latest release tag. Bump rules:
- `feat:` commits → minor bump (e.g., 0.9.0 → 0.10.0)
- Everything else → patch bump (e.g., 0.9.0 → 0.9.1)

For major version bumps, manually set the version.

## Commit Conventions

Conventional Commits format: `<type>: <description>`

Types: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`

Stage related changes together in logical commits. The release commit (`chore: release vX.Y.Z`) includes only version bumps and CHANGELOG.

## Shell Conventions

`install.sh` and test scripts follow POSIX shell (`#!/bin/sh`, not bash). No `jq` — use `sed`/`grep` for JSON parsing. All variables double-quoted. The `ask()` function defaults to "Y" when piped non-interactively.

## Local Development

```bash
claude plugin marketplace add ./path/to/exasol-agent-skills
claude plugin install exasol@exasol-skills
```

After changing skill/reference files, reinstall the plugin (update does not re-copy files if the version is unchanged):

```bash
claude plugin uninstall exasol@exasol-skills --scope user
claude plugin install exasol@exasol-skills
```

Then start a new Claude Code session.
