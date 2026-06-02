# notebook-connector Validation

Use these checks before handing off to extension-deployment skills.

## CLI Validation

```bash
scs check ai_config.db
scs check --connect ai_config.db
```

## Python Validation

Use the executable template:

- `scripts/validate_config.py`

It demonstrates:

- opening a pyexasol connection from notebook-connector config
- opening a BucketFS object from the same config
- doing a minimal smoke test before continuing

## Guidance

- Prefer `scs check --connect` for terminal-first workflows.
- Prefer the Python smoke test for notebook or automation workflows.
- If validation fails, fix config first instead of continuing to TE or TXAIE deployment.
