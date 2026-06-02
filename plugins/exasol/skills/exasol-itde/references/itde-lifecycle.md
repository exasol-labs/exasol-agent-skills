# ITDE Lifecycle

Install the Docker extra:

Use this dependency set when the user wants notebook-connector to manage a local Docker-backed Exasol instance.

```bash
pip install "notebook-connector[docker-db]"
```

## Executable Templates

Use these scripts as the primary editable examples:

- `scripts/bring_itde_up.py` starts the local Exasol container after saving the requested memory and disk sizing values.
- `scripts/check_itde_status.py` checks whether the container is ready and reachable.
- `scripts/restart_itde.py` restarts the managed local Exasol container.
- `scripts/take_itde_down.py` stops and removes the managed local Exasol container.

## Notes

- `bring_itde_up` populates the secure config store with DB and BucketFS values automatically.
- prefer the scripts when generating runnable code for the user
- keep inline guidance focused on lifecycle decisions, not full executable blocks
