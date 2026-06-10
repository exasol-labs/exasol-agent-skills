# notebook-connector SLC Workflows

Use this reference when the user wants Script Language Container workflows via Notebook Connector Python APIs.

## Required Extra

```bash
pip install "notebook-connector[slc]"
```

## Register an SLC

```python
from exasol.nb_connector.slc import ScriptLanguageContainer

ScriptLanguageContainer.create(
    secrets=my_secrets,
    name="my_slc",
    flavor="python3-ds-EXASOL-7.1.0",
)
```

This registers the SLC in the `Secrets` store and derives a language alias like `CUSTOM_SLC_MY_SLC`.

## Build and Upload

```python
from exasol.nb_connector.slc import ScriptLanguageContainer

slc = ScriptLanguageContainer(secrets=my_secrets, name="my_slc")
slc.deploy()
```

`deploy()` builds the SLC, uploads it to BucketFS, and stores the activation definition.

## Activate for a Session

```python
from exasol.nb_connector.language_container_activation import (
    get_activation_sql,
    open_pyexasol_connection_with_lang_definitions,
)

print(get_activation_sql(my_secrets))

conn = open_pyexasol_connection_with_lang_definitions(my_secrets)
conn.execute("SELECT MY_UDF() FROM DUAL")
```

## Guidance

- Use this path for Notebook Connector SLC lifecycle questions.
- Use the main UDF references for UDF authoring, ExaIterator behavior, and SQL syntax.
- If the user still needs BucketFS or base config, activate `exasol-bucketfs` or `exasol-ai-setup` first.
