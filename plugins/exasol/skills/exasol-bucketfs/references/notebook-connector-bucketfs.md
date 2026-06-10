# notebook-connector BucketFS APIs

Use this reference when the user wants BucketFS access through Notebook Connector Python helpers instead of `exapump`.

## Configuration

The `Secrets` store should contain:

- `bfs_host_name` or `db_host_name`
- `bfs_port`
- `bfs_service`
- `bfs_bucket`
- `bfs_user`
- `bfs_password`
- optionally `bfs_encryption`

For ITDE, these are populated automatically by `bring_itde_up(...)`.

## Bucket API

```python
from exasol.nb_connector.connections import get_udf_bucket_path, open_bucketfs_bucket

bucket = open_bucketfs_bucket(my_secrets)
with open("my_model.pkl", "rb") as model_file:
    bucket.upload("models/my_model.pkl", model_file)

print(get_udf_bucket_path(my_secrets))
```

`get_udf_bucket_path()` returns the UDF-visible base path, for example `/buckets/bfsdefault/default`.

## PathLike API

```python
from exasol.nb_connector.connections import open_bucketfs_location

location = open_bucketfs_location(my_secrets)
(location / "data" / "file.txt").write(b"hello bucketfs")
content = (location / "data" / "file.txt").read()
```

## Guidance

- Use the raw bucket API when the example already speaks in `bucket.upload(...)`.
- Use the `PathLike` API when the user wants Pythonic path composition with `/`.
- If config is missing, switch to `exasol-ai-setup` first.
