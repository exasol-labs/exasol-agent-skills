# notebook-connector Connection Helpers

Use the scripts in `scripts/` as the primary runnable/editable examples:

- `check_backend.py`
- `open_pyexasol.py`
- `open_sqlalchemy.py`
- `open_ibis.py`
- `open_bucketfs.py`

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
