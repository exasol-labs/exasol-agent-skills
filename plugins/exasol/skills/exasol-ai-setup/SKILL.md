---
name: exasol-ai-setup
description: "Set up notebook-connector configuration for Exasol AI workflows. Covers the scs CLI, the Secrets Python API, configuration validation, and choosing the right setup path before using AI-Lab, ITDE, Transformers Extension, or Text AI Extension."
---

# Exasol AI Setup Skill

Trigger when the user mentions **notebook-connector**, **SCS**, **scs**, **secure config store**, **Secrets**, **configure notebook-connector**, **AI setup**, **set up credentials for TE**, **set up credentials for TXAIE**, **first-time notebook-connector setup**, or similar setup tasks.

## Purpose

This skill establishes the configuration that later notebook-connector skills depend on.

It does **not** deploy AI extensions itself. After configuration is complete:

- activate **exasol-ai-lab** for bundled notebooks or JupyterLab
- activate **exasol-itde** for the local Docker database workflow
- activate **exasol-notebook-connections** for connection helper code
- activate **exasol-transformers** for the Transformers Extension
- activate **exasol-text-ai** for the Text AI Extension

## Routing Algorithm

Choose the narrowest path that matches the user request:

1. **CLI-based configuration**
   - Trigger phrases: `scs`, `configure onprem`, `configure saas`, `configure docker-db`, `scs check`, `scs show`
   - Load: `references/scs-cli.md`

2. **Python-based configuration**
   - Trigger phrases: `Secrets`, `AILabConfig`, `save config in python`, `notebook cell`, `script`
   - Load: `references/secrets-python.md`
   - Use scripts from: `scripts/`

3. **Validation / smoke tests**
   - Trigger phrases: `check config`, `verify connection`, `validate notebook-connector`, `smoke test`
   - Load: `references/validation.md`
   - Use scripts from: `scripts/`

4. **JupyterLab / bundled notebooks**
   - Activate **exasol-ai-lab**

5. **Local Docker DB / ITDE**
   - Activate **exasol-itde**

6. **Connection helper APIs**
   - Activate **exasol-notebook-connections**

7. **Transformers Extension**
   - Activate **exasol-transformers**

8. **Text AI Extension**
   - Activate **exasol-text-ai**

Multiple routes can apply. Load all matching references before responding.

## Default Guidance

- Prefer the **CLI path** when the user wants reproducible terminal steps.
- Prefer the **Python path** when the user wants notebook cells, automation, or agent-generated code.
- Before handing off to TE or TXAIE, run either:
  - `scs check --connect <scs-file>`, or
  - a short Python connection smoke test from `scripts/validate_config.py`

## Safety Rules

- Do not guess SaaS account IDs, PATs, passwords, or BucketFS credentials.
- Do not read secrets from config files unless the user explicitly provides them.
- Do not start JupyterLab unless the user asks for it.
