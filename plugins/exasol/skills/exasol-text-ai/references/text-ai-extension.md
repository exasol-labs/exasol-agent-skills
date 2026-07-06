# Notebook Connector Text AI Extension

Use this reference for the Python setup flow and extraction workflows of the
Text AI Extension.

It covers:

- `deploy_license(...)`
- `initialize_text_ai_extension(...)`
- `Extraction(...)`
- `NamedEntityExtractor`
- `PipelineExtractor` with `StandardExtractor`
- `BranchExtractor`

Keep setup prerequisites in `Secrets` first, then use this reference for the
extension-specific workflow and validation.

Current notebook-connector main behavior to preserve in this skill:

- `deploy_license(...)` can use the bundled community license when no custom
  license arguments are supplied
- `initialize_text_ai_extension(...)` ensures the shared BucketFS connection
  and model-subdirectory config values as part of its setup flow
- `initialize_text_ai_extension(...)` installs three default Hugging Face
  models when `install_models=True`
- `Extraction.run(...)` opens a DB connection, activates the TXAIE language
  container for the session, and executes the extraction workflow

## Step 1: Deploy a License

The Text AI Extension requires a license before DB objects can be created.

Use the built-in community license for non-commercial and evaluation use:

```python
from exasol.nb_connector.text_ai_extension_wrapper import deploy_license

deploy_license(my_secrets)
```

Or pass a file or inline content:

```python
from pathlib import Path

deploy_license(my_secrets, license_file=Path("text-ai-license.yaml"))
deploy_license(my_secrets, license_content="signature: ...")
```

## Step 2: Initialize the Extension

Use this first-run path when the user wants notebook-connector to install the
language container, default models, and UDF scripts.

```python
from exasol.nb_connector.text_ai_extension_wrapper import initialize_text_ai_extension

initialize_text_ai_extension(my_secrets)
```

`initialize_text_ai_extension()` can:

1. upload the TXAIE Script Language Container to BucketFS
2. install the default Hugging Face models into BucketFS
3. deploy the TXAIE scripts into the configured schema

Useful selective flags:

```python
from pathlib import Path

initialize_text_ai_extension(
    my_secrets,
    version="<txaie-version>",
    container_file=Path("/tmp/txaie.tar.gz"),
    install_slc=False,
    install_models=False,
    install_scripts=True,
    allow_override_language_alias=True,
)
```

## Step 3: Run an Extraction

The `Extraction` class wraps one or more UDF calls. Provide an extractor that
defines which UDFs to invoke, for example `NamedEntityExtractor` for named
entity recognition or a pipeline built with `StandardExtractor`.

Text AI extraction is incremental: it processes only source rows for which no
results have been written yet. Some workflows also create support and lookup
tables in addition to the main output table.

Calling `extraction.run(my_secrets)` opens a database connection, activates the
Text AI language container for the session, and executes the extraction SQL
against the configured source and output tables.

### Named Entity Extraction

```python
from exasol.nb_connector.text_ai_extension_wrapper import Extraction
from exasol.ai.text.extractors.named_entity_extractor import NamedEntityExtractor

extraction = Extraction(
    extractor=NamedEntityExtractor(),
    output="MY_SCHEMA.EXTRACTION_RESULTS",
)
extraction.run(my_secrets)
```

### Pipeline Extraction

Use this when the user wants a reusable preprocessing workflow rather than a
single extractor.

```python
from exasol.nb_connector.text_ai_extension_wrapper import Extraction
from exasol.ai.text.extraction.abstract_extraction import Defaults, Output
from exasol.ai.text.extractors.extractor import PipelineExtractor
from exasol.ai.text.extractors.source_table_extractor import (
    NameSelector,
    SchemaSource,
    SourceTableExtractor,
    TableSource,
)
from exasol.ai.text.extractors.standard_extractor import StandardExtractor

src_extractor = SourceTableExtractor(
    source=TableSource(
        source=SchemaSource("MY_SCHEMA"),
        table_names=NameSelector(["CUSTOMER_SUPPORT_TICKETS"]),
    )
)
std_extractor = StandardExtractor()

extraction = Extraction(
    extractor=PipelineExtractor(steps=[src_extractor, std_extractor]),
    output=Output(db_schema="MY_SCHEMA"),
    defaults=Defaults(),
)
extraction.run(my_secrets)
```

### Branch Extraction

Use this when the workflow should fan out into multiple extractor branches from
the same source data.

```python
from exasol.nb_connector.text_ai_extension_wrapper import Extraction
from exasol.ai.text.extraction.abstract_extraction import Defaults, Output
from exasol.ai.text.extractors.extractor import BranchExtractor, PipelineExtractor
from exasol.ai.text.extractors.named_entity_extractor import NamedEntityExtractor
from exasol.ai.text.extractors.source_table_extractor import (
    NameSelector,
    SchemaSource,
    SourceTableExtractor,
    TableSource,
)
from exasol.ai.text.extractors.topic_classifier_extractor import TopicClassifierExtractor

src_extractor = SourceTableExtractor(
    source=TableSource(
        source=SchemaSource("MY_SCHEMA"),
        table_names=NameSelector(["CUSTOMER_SUPPORT_TICKETS"]),
    )
)
branched_extractors = BranchExtractor(
    steps=[
        NamedEntityExtractor(),
        TopicClassifierExtractor(),
    ]
)

extraction = Extraction(
    extractor=PipelineExtractor(steps=[src_extractor, branched_extractors]),
    output=Output(db_schema="MY_SCHEMA"),
    defaults=Defaults(),
)
extraction.run(my_secrets)
```

## Validation

Validate TXAIE in layers:

- `deploy_license(my_secrets)` should complete without raising a license-deployment error
- `initialize_text_ai_extension(my_secrets)` should complete without language-container or script-install errors
- after setup, run one small `Extraction(...)` workflow against known source tables rather than a large batch job first

Success signals:

- license deployment completes
- initialization completes and the language/container setup is persisted
- a small extraction run writes output rows without missing-license or missing-language errors

Expected failure mode:

- if the source tables, DB config, BucketFS config, or extension assets are missing, extraction should fail until **exasol-ai-setup** and the required DB objects are in place
