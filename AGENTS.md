# AGENTS.md

## What This Repo Is

A skills marketplace for AI coding agents (Claude Code and OpenAI Codex) that gives them expertise in Exasol databases — guided Exasol Personal setup (local on macOS or AWS/Azure/Exoscale/STACKIT), exapump CLI, Exasol SQL, UDFs, BucketFS, cloud data loading, virtual schemas, and custom virtual schema adapter development.

## Architecture

**Plugin hierarchy:** marketplace → plugin → skills + commands → references

- `.claude-plugin/marketplace.json` — discovery entry point; lists plugins with version
- `plugins/exasol/.claude-plugin/plugin.json` — plugin metadata; version must match marketplace
- `plugins/exasol/skills/exasol/SKILL.md` — top-level router skill; public user model is `/exasol <task>` or natural-language Exasol requests
- `plugins/exasol/skills/*/SKILL.md` — specialized skills with routing algorithms that load only the reference files relevant to the task (progressive disclosure). Skills: `exasol` (top-level router), `exasol-setup-personal` (folder `setup-personal`; guided local-or-cloud deployment that defers to the upstream `exasol/exasol-personal` docs), `exasol-database` (SQL/exapump), `exasol-import` (native IMPORT and exapump file movement into Exasol), `exasol-export` (native EXPORT and exapump file movement out of Exasol), `exasol-cloud-storage-extension` (Cloud Storage Extension import/export workflows), `exasol-jdbc-virtual-schemas` (JDBC/database-source virtual schema workflows), `exasol-document-virtual-schemas` (document-file virtual schema workflows for S3/GCS/Azure object storage), `exasol-virtual-schema-adapter-development` (custom virtual schema adapter build, packaging, and debugging workflows), `exasol-udfs` (UDFs/SLCs), `exasol-bucketfs` (BucketFS), `exasol-ai-setup` (notebook-connector setup), `exasol-itde` (local Docker Exasol lifecycle), `exasol-notebook-connections` (Python connection helpers), `exasol-text-ai` (Text AI Extension), `exasol-transformers` (Transformers Extension)
- `plugins/exasol/commands/exasol.md` — unified `/exasol` slash command router (Claude Code only)
- `plugins/exasol/skills/*/references/*.md` — detailed docs loaded on-demand by SKILL.md routing

**Installer (`install.sh`)** — curl-pipeable, idempotent, POSIX shell (no bash, no jq). Supports both agents:
- Agent selection via `AGENT` env var (`claude`, `codex`, `both`) or interactive prompts; non-interactive defaults to both
- Claude Code path: `claude plugin marketplace add/update` + `claude plugin install/update`
- Codex path: pinned `skills` CLI; interactive and curl-piped terminal runs show the skill picker through `/dev/tty`, while non-interactive runs use `--skill '*' --global --yes`; both verify the shared `exasol` router afterwards
- Shared: exapump version check via GitHub API; interactive install/update requires confirmation, and non-interactive install/update requires `INSTALL_EXAPUMP=yes`

## Testing

All installer tests run in Docker with mocked CLIs. **Do not run tests outside Docker** — the mocks replace `claude`, `curl`, `npx`, and `exapump` via PATH injection.

```bash
# Build once
docker build -f Dockerfile.test -t installer-test .

# Run all 9 scenarios
docker run --rm -e SCENARIO=fresh        installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=fresh-exapump installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=exapump-api-failure installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=idempotent   installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=update       installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=fresh-claude installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=fresh-codex  installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=codex-verification-failure installer-test sh test/test-installer.sh
docker run --rm -e SCENARIO=piped-interactive-codex installer-test sh test/test-installer.sh
```

| Scenario | What it tests |
|----------|---------------|
| `fresh` | First-time install: no exapump, both agents |
| `fresh-exapump` | First-time install with explicit non-interactive exapump opt-in |
| `exapump-api-failure` | Continues agent installation when the optional exapump release lookup fails |
| `idempotent` | Re-run when everything is already up to date |
| `update` | Upgrade from an older plugin + exapump version |
| `fresh-claude` | Claude Code only (`AGENT=claude`), npx absent |
| `fresh-codex` | Codex only (`AGENT=codex`), claude CLI absent |
| `codex-verification-failure` | Rejects a successful Codex CLI exit when no shared router was installed |
| `piped-interactive-codex` | Verifies that `curl ... | sh` reads agent and Codex skill selections from the controlling terminal |

Mock files in `test/`: `mock-claude.sh`, `mock-curl.sh`, `mock-exapump.sh`, `mock-npx.sh`. They use `$STATE_DIR` (`/tmp/mock-claude-state`) to track state via files (e.g., `marketplace`, `plugin`, `codex_skills`, `plugin_version`).

Validate manifests (outside Docker):

```bash
claude plugin validate .
claude plugin validate ./plugins/exasol
```

Test the release tag validator locally:

```bash
sh test/test-release-tag.sh
```

Validate package, changelog, and existing-tag version consistency:

```bash
sh .github/scripts/validate-package-version.sh --newer-than-tags
```

Validate a specific release tag and commit:

```bash
sh .github/scripts/validate-release-tag.sh vX.Y.Z <tag-commit> origin/main
```

## CI

`.github/workflows/ci.yml` runs on push to `main` and PRs:
1. **validate-plugin** — JSON validity + version consistency between both manifests and the changelog + version bump check on PRs (must be greater than existing tags)
2. **test-installer** — all 9 Docker scenarios
3. **check-links** — validates Markdown links in a `Check Links` job shaped like Exasol `notebook-connector`'s documentation check; this Markdown-only repo runs `npx markdown-link-check@3.14.2` with `.github/markdown_check_config.json` instead of Notebook Connector's Poetry/Nox docs stack

`.github/workflows/release.yml` runs after a maintainer pushes a `v*` tag:
- It runs the reusable CI workflow and publishes only after all CI jobs pass
- It validates that the tag matches both manifests and points to a commit on `main`
- It checks that the version matches the changelog and is newer than existing release tags
- It creates a release only for an existing tag
- It serializes release runs to avoid concurrent publication

## Versioning and Releasing

Version is synchronized in three places that **must always match**:
- `.claude-plugin/marketplace.json` → `metadata.version`
- `plugins/exasol/.claude-plugin/plugin.json` → `version`
- `CHANGELOG.md` → latest `## vX.Y.Z` heading

Releases are automated after an explicit `v*` tag push. PR merges do not publish releases.
Repository administrators must restrict creation of `v*` tags to release maintainers with a GitHub tag ruleset.

**PR authors must bump the version** in both manifests, add the matching changelog heading, and keep Markdown links passing the CI link checker. CI validates the version is strictly greater than every existing stable release tag. Bump rules:
- `feat:` commits → minor bump (e.g., 0.9.0 → 0.10.0)
- Everything else → patch bump (e.g., 0.9.0 → 0.9.1)

For major version bumps, manually set the version.

## Commit Conventions

Conventional Commits format: `<type>: <description>`

Types: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`

Stage related changes together in logical commits. The release commit (`chore: release vX.Y.Z`) includes only version bumps and CHANGELOG.

## Shell Conventions

`install.sh` and test scripts follow POSIX shell (`#!/bin/sh`, not bash). No `jq` — use `sed`/`grep` for JSON parsing. All variables double-quoted. Interactive prompts use the controlling terminal so they remain available when the script itself is piped.

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
