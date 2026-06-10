# Notebook Connector Connection Helpers

All helpers accept a `Secrets` object and derive their connection parameters
from it automatically.

## Executable Templates

Use the scripts in `scripts/` as the primary runnable/editable examples:

- `check_backend.py`
- `open_pyexasol.py`
- `open_sqlalchemy.py`
- `open_ibis.py`
- `open_bucketfs.py`

## Database Helpers

### `open_pyexasol_connection(conf, **kwargs)`

- best for raw SQL execution and UDF-related work
- supports context-manager usage
- does **not** apply `db_schema` automatically
- pass `schema=conf.get(CKey.db_schema)` when a default schema is needed

### `open_sqlalchemy_connection(conf, **kwargs)`

- returns a SQLAlchemy engine
- applies `db_schema` automatically
- use it for `pandas.read_sql`, ORM work, or tooling that expects SQLAlchemy

### `open_ibis_connection(conf, **kwargs)`

- returns an Ibis connection backed by the Exasol dialect
- applies `db_schema` automatically
- use it for dataframe-like query composition and metadata inspection

## BucketFS Helpers

### `open_bucketfs_connection(conf)`

- deprecated helper
- prefer `open_bucketfs_bucket(conf)` unless the user explicitly asks for the legacy name

### `open_bucketfs_bucket(conf)`

- resolves the configured BucketFS bucket object
- use `bucket.upload(target_path, file_object)` to stream files into BucketFS

### `open_bucketfs_location(conf)`

- returns a path-like BucketFS location
- use `/` to join paths, `.write(...)` to upload bytes, and `.read()` to fetch them

### `get_udf_bucket_path(conf)`

- returns the absolute path Exasol UDFs use to read from the configured bucket
- append the uploaded relative path to build the final `/buckets/...` UDF-visible path

## Helper Values

The agent should know these helpers exist and mention them when relevant:

- `get_backend(conf)`
- `get_external_host(conf)`
- `get_saas_database_id(conf)`
- `get_udf_bucket_path(conf)`
- `open_bucketfs_bucket(conf)`
- `open_bucketfs_location(conf)`
- `open_pyexasol_connection(conf)`
- `open_sqlalchemy_connection(conf)`
- `open_ibis_connection(conf)`
