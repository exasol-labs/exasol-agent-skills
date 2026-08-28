# AGENTS.md

## What This Repo Is

A skills marketplace for AI coding agents (Claude Code and OpenAI Codex) that gives them expertise in Exasol databases — guided Exasol Personal setup (local on macOS or AWS/Azure/Exoscale/STACKIT), exapump CLI, Exasol SQL, UDFs, BucketFS, cloud data loading, virtual schemas, and custom virtual schema adapter development.

## Architecture

**Plugin hierarchy:** marketplace → plugin → skills + commands → references

- `.claude-plugin/marketplace.json` — discovery entry point; lists plugins with version
- `plugins/exasol/.claude-plugin/plugin.json` — plugin metadata; version must match marketplace
- `plugins/exasol/skills/exasol/SKILL.md` — top-level router skill; public user model is `/exasol <task>` or natural-language Exasol requests
- `plugins/exasol/skills/*/SKILL.md` — specialized skills with routing algorithms that load only the reference files relevant to the task (progressive disclosure). Skills: `exasol` (top-level router), `exasol-setup-personal` (folder `setup-personal`; guided local-or-cloud deployment that defers to the upstream `exasol/exasol-personal` docs), `exasol-database` (SQL/exapump), `exasol-import` (native IMPORT and exapump file movement into Exasol), `exasol-export` (native EXPORT and exapump file movement out of Exasol), `exasol-cloud-storage-extension` (Cloud Storage Extension import/export workflows), `exasol-jdbc-virtual-schemas` (JDBC/database-source virtual schema workflows), `exasol-document-virtual-schemas` (document-file virtual schema workflows for S3/GCS/Azure object storage), `exasol-virtual-schema-adapter-development` (custom virtual schema adapter build, packaging, and debugging workflows), `exasol-extension-catalog` (tool and architecture selection), `exasol-distributed-ml` (distributed ML and GPU workflows), `exasol-udfs` (UDFs/SLCs), `exasol-bucketfs` (BucketFS), `exasol-ai-setup` (notebook-connector setup), `exasol-itde` (local Docker Exasol lifecycle), `exasol-notebook-connections` (Python connection helpers), `exasol-text-ai` (Text AI Extension), `exasol-transformers` (Transformers Extension)
- `plugins/exasol/commands/*.md` — thin Claude-only `/exasol` and compatibility `/bucketfs` entry points that delegate to the shared router
- `plugins/exasol/skills/*/references/*.md` — detailed docs loaded on-demand by SKILL.md routing
- `plugins/exasol/skills/_template/` — contributor skeleton, not a skill; it ships `SKILL.md.template` so that nothing discovers it as one

**Installer (`install.sh`)** — curl-pipeable, idempotent, POSIX shell (no bash, no jq). Supports both agents:
- Agent selection via `AGENT` env var (`claude`, `codex`, `both`) or interactive prompts; non-interactive defaults to both
- Claude Code path: `claude plugin marketplace add/update` + `claude plugin install/update`
- Codex path: pinned `skills` CLI; interactive and curl-piped terminal runs keep prompts and the skill picker on `/dev/tty` when standard streams are redirected, while non-interactive runs use `--skill '*' --global --yes`; both verify the shared `exasol` router afterwards
- Shared: exapump version check via GitHub API; interactive install/update requires confirmation, and non-interactive install/update requires `INSTALL_EXAPUMP=yes`

## Skill Conventions

`python3 test/check-package.py` enforces the structural rules and names exactly
what it wants when it fails; run it before pushing. This section covers only
what it cannot check — the judgement calls that decide whether a skill is ever
loaded, and whether it is worth loading.

### Adding a skill

Copy [`plugins/exasol/skills/_template/`](plugins/exasol/skills/_template/) to
`plugins/exasol/skills/<skill-name>/` and rename `SKILL.md.template` to
`SKILL.md`. (The template ships no `SKILL.md` of its own because any directory
under `skills/` that has one becomes a skill every user of the plugin sees in
their skill list.) Write the `description` first — it is the part that decides
whether the skill is ever loaded.

Then run the checks under [Testing](#testing) before pushing. They cover the
structural requirements and name what is missing, including the entries your
skill needs in the router and the extension catalog, so there is no checklist of
them here to drift. Version bumps follow
[Versioning and Releasing](#versioning-and-releasing).

Two things no check can see, and therefore the two that go stale: the skill list
in this file's [Architecture](#architecture) section, and the user-facing feature
list in `README.md`. Update both.

### Shape: a thin SKILL.md routing into references/

A `SKILL.md` is a router, not a manual. It states its scope, decides which
reference file answers the request, and loads that file. Long-form material —
SQL and code samples, option tables, troubleshooting trees — belongs in
`references/*.md`, which an agent reads only when a route matches. That is the
whole point of progressive disclosure: content inlined in `SKILL.md` is paid for
by every session that loads the skill, including the sessions that needed one
paragraph of it.

Skills here sit between roughly 20 and 100 lines of `SKILL.md`. Treat 100 lines
as the ceiling, and a `SKILL.md` growing past it as a signal that content should
move into `references/` rather than as a budget to spend. Reference files
have no such limit; several exceed 400 lines, which is fine precisely because
they load on demand.

The top-level `exasol` router has no `references/` by design; it holds dispatch
rules and nothing else.

### The directory name and the front-matter `name` are one identifier

They must be the same string because two different consumers each use one of
them, and both are visible. Claude Code addresses a skill as
`exasol:<directory-name>`, while everything inside the package — the router's
`Activate:` markers, the catalog handoffs, the `Use **exasol-foo**` pointers that
skills use to send work to each other — refers to it by its front-matter `name`.
When the two diverge, the identifier the package tells an agent to activate is
not the identifier that resolves.

If the two ever collide — a directory name you want and a `name` you want — rename
the directory. Teaching the validator an exception instead makes the mismatch
permanent and hides it from the next contributor, who has no reason to expect it.

### Trigger phrases belong in the front-matter `description`

The `description` is the primary routing surface. Both agents surface a skill to
the model by its `name` and `description` only — the body is read after the skill
is chosen — so the description is what a routing decision has to work from: what
the skill is for, in the words a user would use, followed by the concrete surface
it covers. Write it the way the existing skills do — a purpose sentence, then
`Covers …`.

Two consequences:

- Anything an agent cannot recover semantically must appear in the `description`
  verbatim. Opaque literal identifiers are the case that matters — container and
  language names, configuration keys, API class names, fully-qualified script
  entry points, acronyms of product names (`PYTHON3_TXAIE`,
  `CLOUD_STORAGE_EXTENSION.IMPORT_PATH`, and their kind). A user who types one of
  those is naming a single skill, but no paraphrase reconstructs the string, so
  if it is not in the description the match is lost. The test: could a user
  plausibly type this string, and would anything in my description match it? If
  no, it goes in the description.
- The trigger phrases inside a skill's own `Routing Algorithm` select a
  *reference file*, not the skill. Scope them to that job; they are not a second
  copy of the description. A phrase that would decide which skill runs belongs in
  the description, and a precedence conflict between two skills belongs in the
  router.

### Router versus catalog

`skills/exasol` and `exasol-extension-catalog` read alike and do different jobs.
The router is pure dispatch: it answers "which of our skills handles this
request?", holds no Exasol knowledge — only precedence rules, dependency order,
and shared safety rules — and its reasoning should never surface to the user; it
exists so that Claude Code and Codex share one routing source, which is why the
files under `commands/` delegate to it rather than copying it. The catalog is a
destination: it answers "which Exasol product, extension, or integration should I
use?", carries real curated content in six capability families, and hands off to
a specialized skill once the choice is made. A new skill accordingly appears in
both files — as a router route (which skill runs) and as a catalog handoff (where
a user who was comparing products lands) — and those two entries say different
things. If you find yourself writing the same sentence in both, one of them is in
the wrong file.

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

Validate package consistency and credential-like content:

```bash
python3 test/check-package.py
sh test/check-security.sh
```

## CI

`.github/workflows/ci.yml` runs on push to `main` and PRs:
1. **validate-plugin** — JSON validity + version consistency between both manifests and the changelog + version bump check on PRs (must be greater than existing tags)
2. **test-installer** — all 9 Docker scenarios
3. **package-safety** — validates skill metadata, routing references, command delegation, workflow and manifest keys, and credential-like content
4. **check-links** — validates Markdown links in a `Check Links` job shaped like Exasol `notebook-connector`'s documentation check; this Markdown-only repo runs `npx markdown-link-check@3.14.2` with `.github/markdown_check_config.json` instead of Notebook Connector's Poetry/Nox docs stack

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

`install.sh` and test scripts follow POSIX shell (`#!/bin/sh`, not bash). No `jq` — use `sed`/`grep` for JSON parsing. All variables double-quoted. Interactive prompts and selectors use the controlling terminal so they remain visible when the script is piped or standard output is redirected.

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
