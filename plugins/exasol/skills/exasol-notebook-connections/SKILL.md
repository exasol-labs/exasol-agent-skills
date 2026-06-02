---
name: exasol-notebook-connections
description: "Use notebook-connector's Python connection helpers for Exasol, BucketFS, SQLAlchemy, and Ibis. Covers open_pyexasol_connection, open_sqlalchemy_connection, open_ibis_connection, open_bucketfs_bucket, open_bucketfs_location, get_backend, and related helper functions."
---

# Exasol notebook-connector Connections Skill

Trigger when the user mentions **open_pyexasol_connection**, **open_sqlalchemy_connection**, **open_ibis_connection**, **open_bucketfs_bucket**, **BucketFS location**, **get_backend**, **connection helper**, or **use notebook-connector from Python**.

## Routing Algorithm

1. **Database connection helpers**
   - Trigger phrases: `pyexasol`, `sqlalchemy`, `ibis`, `open connection`
   - Load: `references/connections-api.md`
   - Use scripts from: `scripts/`

2. **BucketFS object helpers**
   - Trigger phrases: `open_bucketfs_bucket`, `open_bucketfs_location`, `bucket path`
   - Load: `references/connections-api.md`
   - Use scripts from: `scripts/`

3. **Config not set up yet**
   - Activate **exasol-ai-setup**

## Notes

- This skill assumes the secure config store is already populated.
- Prefer these helpers over ad hoc connection construction when the user is already using notebook-connector.
