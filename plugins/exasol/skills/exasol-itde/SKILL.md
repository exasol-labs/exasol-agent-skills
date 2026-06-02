---
name: exasol-itde
description: "Use notebook-connector's itde_manager to run a local Docker-based Exasol database. Covers bring_itde_up, get_itde_status, restart_itde, take_itde_down, and how ITDE populates notebook-connector configuration automatically."
---

# Exasol ITDE Skill

Trigger when the user mentions **ITDE**, **docker-db**, **local Exasol Docker database**, **bring_itde_up**, **restart_itde**, **take_itde_down**, or **local notebook-connector database setup**.

## Routing Algorithm

1. **Start local Docker DB**
   - Trigger phrases: `bring_itde_up`, `start local exasol`, `docker-db`
   - Load: `references/itde-lifecycle.md`
   - Use scripts from: `scripts/`

2. **Check status / restart / tear down**
   - Trigger phrases: `get_itde_status`, `restart_itde`, `take_itde_down`, `container status`
   - Load: `references/itde-lifecycle.md`
   - Use scripts from: `scripts/`

3. **Config not present yet**
   - Activate **exasol-ai-setup**

## Notes

- ITDE is the easiest local development database path for notebook-connector.
- `bring_itde_up` populates the secure config store with the generated DB and BucketFS connection details automatically.
- After ITDE is ready, other notebook-connector connection APIs can be used without manual DB/BucketFS entry.
