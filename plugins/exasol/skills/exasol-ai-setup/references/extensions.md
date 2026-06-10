# Notebook Connector Extension Setup

Use this reference for Notebook Connector workflows that prepare Exasol AI extensions after the SCS is configured.

## Transformers Extension

Required extra:

```bash
pip install "notebook-connector[transformers]"
```

Main entry point:

```python
from exasol.nb_connector.transformers_extension_wrapper import initialize_te_extension

initialize_te_extension(my_secrets)
```

`initialize_te_extension()` can:

- upload the pre-built SLC to BucketFS
- create the BucketFS `CONNECTION` object
- create the Hugging Face token `CONNECTION` object when `huggingface_token` is set
- deploy the TE UDF scripts into the configured schema

Useful follow-up:

```python
from exasol.nb_connector.language_container_activation import get_activation_sql

print(get_activation_sql(my_secrets))
```

## Text AI Extension

Deploy a license first:

```python
from exasol.nb_connector.text_ai_extension_wrapper import deploy_license

deploy_license(my_secrets)
```

Install the extension:

```python
from exasol.nb_connector.text_ai_extension_wrapper import initialize_text_ai_extension

initialize_text_ai_extension(my_secrets)
```

`initialize_text_ai_extension()` can install the SLC, default models, and UDF scripts. Individual steps can be disabled with flags such as `install_models=False`.

## Cloud Storage Extension

Use Notebook Connector helpers to download the extension JAR, upload it to BucketFS, compute the UDF-visible path, and deploy the scripts:

```python
import pathlib
from exasol.nb_connector.cloud_storage import setup_scripts
from exasol.nb_connector.connections import (
    get_udf_bucket_path,
    open_bucketfs_bucket,
    open_pyexasol_connection,
)
from exasol.nb_connector.github import Project, retrieve_jar

jar_path = retrieve_jar(Project.CLOUD_STORAGE_EXTENSION, storage_path=pathlib.Path("/tmp"))
bucket = open_bucketfs_bucket(my_secrets)
with open(jar_path, "rb") as jar_file:
    bucket.upload(jar_path.name, jar_file)

udf_jar_path = get_udf_bucket_path(my_secrets) + "/" + jar_path.name
with open_pyexasol_connection(my_secrets, schema="MY_SCHEMA") as conn:
    setup_scripts(conn, schema_name="MY_SCHEMA", bucketfs_jar_path=udf_jar_path)
```

## Guidance

- These workflows require complete DB and BucketFS configuration in the SCS first.
- Validate first with `scs check --connect` or the Python smoke test.
- For deeper SQL, BucketFS path, or SLC activation details, activate the matching local skill.
