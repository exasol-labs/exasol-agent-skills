---
name: exasol-text-ai
description: "Deploy and use the Exasol Text AI Extension with notebook-connector. Covers deploy_license, initialize_text_ai_extension, the Extraction API, default-model installation, and pipeline or branch-based text extraction workflows."
---

# Exasol Text AI Extension Skill

Trigger when the user mentions **Text AI Extension**, **TXAIE**, **deploy_license**, **initialize_text_ai_extension**, **Extraction**, **named entity extraction**, **zero-shot classification**, **feature extraction**, or **PYTHON3_TXAIE**.

## Routing Algorithm

1. **License and extension setup**
   - Trigger phrases: `deploy_license`, `initialize_text_ai_extension`, `txaie`
   - Load: `references/text-ai-extension.md`

2. **Extraction workflows and validation**
   - Trigger phrases: `Extraction`, `NamedEntityExtractor`, `PipelineExtractor`, `BranchExtractor`, `StandardExtractor`
   - Load: `references/text-ai-extension.md`

## Prerequisites

The secure config store must already contain complete DB and BucketFS values. If not, activate **exasol-ai-setup** first.

## Step 1: Deploy a License

The Text AI extension requires a license before DB objects can be created.

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
    version="1.2.3",
    container_file=Path("/tmp/txaie.tar.gz"),
    install_slc=False,
    install_models=False,
    install_scripts=True,
    allow_override_language_alias=True,
)
```

## Step 3: Run an Extraction

The `Extraction` class opens a DB connection, activates the TXAIE language
container for the session, and runs the configured extraction workflow.

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

## Behavior Notes

- extraction is incremental and reuses previously written output tables
- some workflows create support or lookup tables in addition to the main output table
- default-model installation is useful for offline UDF execution after setup

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

## Guidance

- Use **exasol-ai-setup** when SCS, DB, or BucketFS values are still missing.
- Use **exasol-bucketfs** when the user needs to inspect the uploaded SLC or model assets.
- Use **exasol-transformers** when the user needs lower-level, direct TE SQL UDF workflows instead of the higher-level Text AI extraction API.
