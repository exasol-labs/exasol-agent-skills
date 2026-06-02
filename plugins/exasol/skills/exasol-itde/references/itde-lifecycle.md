# ITDE Lifecycle

Install the Docker extra:

```bash
pip install "notebook-connector[docker-db]"
```

## Executable Templates

Use these scripts as the primary editable examples:

- `scripts/bring_itde_up.py`
- `scripts/check_itde_status.py`
- `scripts/restart_itde.py`
- `scripts/take_itde_down.py`

## Notes

- `bring_itde_up` populates the secure config store with DB and BucketFS values automatically.
- prefer the scripts when generating runnable code for the user
- keep inline guidance focused on lifecycle decisions, not full executable blocks
