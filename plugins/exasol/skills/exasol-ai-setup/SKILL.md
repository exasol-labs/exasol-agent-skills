---
name: exasol-ai-setup
description: "Set up notebook-connector configuration for Exasol AI workflows. Covers the scs CLI, the Secrets Python API, configuration validation, ai-lab and ITDE workflows, and preparing Notebook Connector state before BucketFS, SLC, Transformers Extension, Text AI, or cloud-storage work."
---

# Exasol AI Setup Skill

Trigger when the user mentions **notebook-connector**, **SCS**, **scs**, **secure config store**, **Secrets**, **configure notebook-connector**, **AI setup**, **set up credentials for TE**, **set up credentials for TXAIE**, **first-time notebook-connector setup**, or similar setup tasks.

## Purpose

This skill establishes the configuration that later notebook-connector skills depend on.

It establishes the secure configuration and first-run workflow that later
Notebook Connector tasks depend on.

After configuration is complete:

- use this skill for `ai-lab`, `scs`, `Secrets`, ITDE, Transformers Extension, Text AI Extension, and cloud-storage-extension setup questions
- activate **exasol-database** for SQL work and Notebook Connector DB connection helpers
- activate **exasol-bucketfs** for BucketFS file access patterns
- activate **exasol-udfs** for Script Language Containers and UDF activation

## Routing Algorithm

Choose the narrowest path that matches the user request:

1. **CLI-based configuration**
   - Trigger phrases: `scs`, `configure onprem`, `configure saas`, `configure docker-db`, `scs check`, `scs show`, `SCS_FILE`, `SCS_MASTER_PASSWORD`
   - Load: `references/scs-cli.md`

2. **Python-based configuration**
   - Trigger phrases: `Secrets`, `AILabConfig`, `StorageBackend`, `save config in python`, `notebook cell`, `script`
   - Load: `references/secrets-python.md`
   - Use scripts from: `scripts/`

3. **Validation / smoke tests**
   - Trigger phrases: `check config`, `verify connection`, `validate notebook-connector`, `smoke test`, `open_pyexasol_connection`, `get_backend`
   - Load: `references/validation.md`
   - Use scripts from: `scripts/`

4. **AI Lab CLI / bundled notebooks**
   - Trigger phrases: `ai-lab`, `deploy notebooks`, `jupyterlab`, `start notebooks`
   - Load: `references/ai-lab-cli.md`

5. **Local Docker DB / ITDE**
   - Trigger phrases: `ITDE`, `docker-db`, `bring_itde_up`, `restart_itde`, `take_itde_down`
   - Load: `references/itde.md`

6. **Transformers / Text AI / Cloud Storage setup**
   - Trigger phrases: `initialize_te_extension`, `initialize_text_ai_extension`, `deploy_license`, `cloud-storage-extension`, `setup_scripts`
   - Load: `references/extensions.md`

7. **Connection helper APIs, BucketFS, or SLCs**
   - Activate **exasol-database**, **exasol-bucketfs**, or **exasol-udfs** as needed for the deeper API surface after SCS setup is done

Multiple routes can apply. Load all matching references before responding.

## Default Guidance

- Prefer the **CLI path** when the user wants reproducible terminal steps.
- Prefer the **Python path** when the user wants notebook cells, automation, or agent-generated code.
- Before handing off to DB helpers, BucketFS helpers, TE, TXAIE, or SLC work, run either:
  - `scs check --connect <scs-file>`, or
  - a short Python connection smoke test from `scripts/validate_config.py`

## Validation

After writing or updating config, verify it before handing off to downstream skills:

- terminal-first path: run `scs check --connect ai_config.db`
- Python path: run `scripts/validate_config.py`
- quick backend-only check: run `scripts/check_backend.py` from **exasol-notebook-connections**

Success signals:

- the backend resolves to the expected value (`onprem` or `saas`)
- the DB smoke test can run `SELECT 1`
- BucketFS resolution succeeds from the same store

Expected failure mode:

- if the store still contains template values such as `my-db-host` or placeholder SaaS IDs/PATs, connection validation should fail until the user replaces them with real values

## Safety Rules

- Do not guess SaaS account IDs, PATs, passwords, or BucketFS credentials.
- Do not read secrets from config files unless the user explicitly provides them.
- Do not start JupyterLab unless the user asks for it.
