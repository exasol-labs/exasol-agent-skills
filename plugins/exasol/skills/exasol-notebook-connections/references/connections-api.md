# notebook-connector Connection Helpers

Use the scripts in `scripts/` as the primary runnable/editable examples:

- `check_backend.py` shows how to detect whether the stored config targets on-prem, SaaS, or another supported backend.
- `open_pyexasol.py` shows the minimal DB connectivity check using notebook-connector's pyexasol helper.
- `open_sqlalchemy.py` shows how to construct and use a SQLAlchemy engine from notebook-connector config.
- `open_ibis.py` shows how to open an Ibis connection and run a simple metadata call.
- `open_bucketfs.py` shows how to resolve the BucketFS connection, bucket object, and a concrete location inside the bucket.

## Helper Values

The agent should know these helpers exist and mention them when relevant:

- `get_backend(conf)`
- `get_external_host(conf)`
- `get_saas_database_id(conf)`
- `get_udf_bucket_path(conf)`
- `open_bucketfs_connection(conf)`
- `open_bucketfs_bucket(conf)`
- `open_bucketfs_location(conf, "...")`
- `open_pyexasol_connection(conf)`
- `open_sqlalchemy_connection(conf)`
- `open_ibis_connection(conf)`

These names act as a capability index for the agent. Use the scripts when the user wants runnable code, and use this list when the user only needs to know which helper to call.
