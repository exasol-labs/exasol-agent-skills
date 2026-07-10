# Changelog

## v0.19.0

- Add exasol-cloud-storage-extension skill for Cloud Storage Extension loading workflows
- Add exasol-export skill for native Exasol export workflows
- Remove the obsolete combined import/export database reference after splitting import and export into dedicated skills
- Remove remaining import/export workflow details from exasol-database references

## v0.18.0

- Add exasol-distributed-ml skill for distributed ML, GPU acceleration, model lifecycle, and performance workflows

## v0.17.0

- Add exasol-import skill for native Exasol import workflows

## v0.16.1

- Extend exasol-text-ai with notebook-aligned result querying, analytics patterns, and corrected extraction examples

## v0.16.0

- Add exasol-text-ai skill for notebook-connector Text AI Extension workflows
- Route notebook-connector Text AI tasks through the unified Exasol router

## v0.15.0

- Add exasol-transformers skill for notebook-connector Transformers Extension workflows

## v0.14.0

- Add exasol-extension-catalog skill for Exasol tools, extensions, connectors, integrations, and architecture patterns
- Route extension, integration, migration, governance, BI/API, and scale questions through the unified Exasol router

## v0.13.0

- Add exasol-notebook-connections skill for notebook-connector connection helper APIs

## v0.12.0

- Add exasol-itde skill for notebook-connector local Docker database workflows

## v0.11.0

- Add top-level Exasol router skill as the single public entry point for Exasol tasks
- Expand `/exasol` into a unified command router for database, BucketFS, UDF, SLC, and setup workflows
- Document contribution guidelines for adding specialized skills behind the unified router

## v0.10.1

- Add exasol-ai-setup skill for notebook-connector CLI and Python API configuration

## v0.9.0

- Add Exasol Personal setup skill for guided AWS deployment
- Add automated releases on PR merge with version validation in CI
- Move project instructions to AGENTS.md for multi-agent compatibility

## v0.8.0

- Add BucketFS skill for managing files in Exasol's BucketFS
- Add identifier quoting support and variadic UDF documentation

## v0.7.0

- Add OpenAI Codex support via `npx skills add` in the installer
- Installer prompts for agent selection (Claude Code, Codex, or both)
- Support `AGENT` env var (`claude`, `codex`, `both`) for scripted installs
- Update marketplace description for multi-agent support
- Rewrite README with multi-agent docs, skill links, and Codex badge
- Add installer test scenarios for single-agent installs

## v0.6.0

- Replace merge-staging reference with comprehensive import-export reference covering decision framework, all IMPORT/EXPORT formats, cloud sources, error handling, and staging workflows
- Add exasol-udfs skill for UDF development and Script Language Containers
- Split SQL reference into on-demand sections with fine-grained routing

## v0.5.0

- Add curl-pipeable install script with CI pipeline
- Check and offer to install/update exapump during installation
- Auto-create GitHub release on v* tag push

## v0.4.0

- Fix --profile flag placement (must follow subcommand)
- Add reserved keyword handling with live database lookups

## v0.3.0

- Switch from DSN connection strings to exapump connection profiles

## v0.2.0

- Add logo and redesign README

## v0.1.0

- Initial release
- Exasol database skill with exapump CLI reference
- YAML front-matter and algorithmic routing in SKILL.md
- Comprehensive data type reference table
- Connection establishment step with profile detection
- Plugin marketplace scaffolding and installer
