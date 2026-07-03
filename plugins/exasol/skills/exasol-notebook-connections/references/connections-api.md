# Notebook Connector Connection Helpers

All helpers accept a `Secrets` object and derive their connection parameters
from it automatically.
Some helpers also forward `**kwargs` to the underlying client library, so the
agent can override individual parameters without rebuilding the whole
connection config.

Before opening a helper, make sure the `Secrets` store already contains the
required DB or BucketFS settings. For BucketFS, `bfs_host_name` falls back to
`db_host_name` when absent. When the store is configured for SaaS, the same
helpers resolve the database and BucketFS access through the SaaS settings.

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
- forwards extra keyword arguments to `pyexasol.connect(...)`
- pass `schema=conf.get(CKey.db_schema)` when a default schema is needed

### `open_sqlalchemy_connection(conf)`

- returns a SQLAlchemy engine
- applies `db_schema` automatically
- use it for `pandas.read_sql`, ORM work, or tooling that expects SQLAlchemy

### `open_ibis_connection(conf, **kwargs)`

- returns an Ibis connection backed by the Exasol dialect
- applies `db_schema` automatically
- forwards extra keyword arguments to the Ibis backend setup
- use it for dataframe-like query composition and metadata inspection

## BucketFS Helpers

### `open_bucketfs_bucket(conf)`

- resolves the configured BucketFS bucket object
- use `bucket.upload(target_path, file_object)` to stream files into BucketFS

### `open_bucketfs_location(conf)`

- returns a path-like BucketFS location
- use `/` to join paths, `.write(...)` to upload bytes, and `.read()` to fetch them

### `get_udf_bucket_path(conf)`

- returns the absolute path Exasol UDFs use to read from the configured bucket
- append the uploaded relative path to build the final `/buckets/...` UDF-visible path

Typical pattern:

```python
bucket = open_bucketfs_bucket(conf)
with open("my_model.pkl", "rb") as file_obj:
    bucket.upload("models/my_model.pkl", file_obj)

udf_path = get_udf_bucket_path(conf) + "/models/my_model.pkl"
print(udf_path)
```

## Helper Values

The agent should know these helpers exist and mention them when relevant:

- `get_backend(conf)`
- `get_udf_bucket_path(conf)`
- `open_bucketfs_bucket(conf)`
- `open_bucketfs_location(conf)`
- `open_pyexasol_connection(conf)`
- `open_sqlalchemy_connection(conf)`
- `open_ibis_connection(conf)`
