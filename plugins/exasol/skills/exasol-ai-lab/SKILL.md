---
name: exasol-ai-lab
description: "Use the ai-lab CLI to start JupyterLab and deploy notebook-connector's bundled notebooks. Covers ai-lab start, deploy-notebooks, common options, and when to use notebook deployment versus configuration setup."
---

# Exasol AI-Lab Skill

Trigger when the user mentions **ai-lab**, **start JupyterLab**, **deploy notebooks**, **bundled notebooks**, **local notebook root**, or **run notebook-connector notebooks**.

## Routing Algorithm

1. **Start JupyterLab**
   - Trigger phrases: `ai-lab start`, `start jupyterlab`, `open notebooks`
   - Load: `references/ai-lab-cli.md`

2. **Copy notebooks only**
   - Trigger phrases: `deploy-notebooks`, `copy bundled notebooks`, `export notebooks locally`
   - Load: `references/ai-lab-cli.md`

3. **Config not ready yet**
   - Trigger phrases: `first-time setup`, `need credentials`, `need scs`
   - Activate **exasol-ai-setup**

## Notes

- The default JupyterLab port is `49494`.
- `ai-lab start` copies bundled notebooks into the notebook root before starting JupyterLab.
- Existing notebook files are preserved unless the user explicitly uses overwrite during deployment.
