# Notebook Connector Validation

Use these checks before handing off to downstream notebook-connector skills.

## Python Validation

Use the executable template:

- `scripts/validate_config.py`

It demonstrates:

- reading which backend is active
- checking that the required values for that backend are present in the `Secrets` store
- failing early when placeholder values are still present

This is the preferred validation path for this skill.

Typical pattern:

```python
from exasol.nb_connector.connections import get_backend

print(get_backend(conf).name)
```

## Guidance

- Prefer the Python smoke test for notebook or automation workflows.
- If validation succeeds, hand off DB and BucketFS helper checks to **exasol-notebook-connections**.
- If validation fails, fix config first instead of continuing to ITDE, TE, or TXAIE workflows.
