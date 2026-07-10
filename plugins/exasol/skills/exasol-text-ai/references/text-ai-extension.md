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
- querying generated TXAIE tables and views
- notebook-style analytics on extraction results

Keep setup prerequisites in `Secrets` first, then use this reference for the
extension-specific workflow and validation.

If the required DB or BucketFS values are still missing in the secure config
store, switch to **exasol-ai-setup** first and complete its setup-validation
flow before returning here.

Current notebook-connector behavior to preserve in this skill:

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

Prefer a local license file for custom licenses so the content does not end up
embedded in code or notebook history:

```python
from pathlib import Path

deploy_license(my_secrets, license_file=Path("text-ai-license.yaml"))
```

Only use inline content for short-lived local experiments when the content will
not be shared:

```python
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

When `install_models=True`, notebook-connector installs these default models
through `install_model(...)`:

| workflow | default model | `task_type` for `install_model(...)` | model factory |
|----------|----------------|--------------------------------------|----------------|
| semantic feature extraction | `answerdotai/ModernBERT-base` | `feature-extraction` | `AutoModel` |
| named entity extraction | `guishe/nuner-v2_fewnerd_fine_super` | `token-classification` | `AutoModelForTokenClassification` |
| zero-shot classification / default NLI model | `tasksource/ModernBERT-base-nli` | `zero-shot-classification` | `AutoModelForSequenceClassification` |

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

Use the extractor shape that matches the workflow:

| extractor | use it for |
|-----------|------------|
| `NamedEntityExtractor` | direct named-entity extraction |
| `StandardExtractor` | the built-in preprocessing flow with topic classification, keyword search, and named entity recognition |
| `PipelineExtractor` | sequential workflows where one extractor step feeds the next |
| `BranchExtractor` | fan-out workflows where multiple extractors run from the same source step |

For `TopicClassifierExtractor`, follow the branch-extraction example below,
where it is used as one branch inside a `BranchExtractor`.

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

Pattern:

- start with a source-step extractor that defines which source tables or views
  and columns feed the workflow
- add one or more downstream extractor steps that consume that source output
- write the generated TXAIE result objects into the configured schema

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

topics = {"urgent", "not urgent"}

src_extractor = SourceTableExtractor(
    name="DOCUMENTS",
    sources=[
        SchemaSource(
            db_schema=NameSelector(pattern="MY_SCHEMA"),
            tables=[
                TableSource(
                    table=NameSelector(pattern="CUSTOMER_SUPPORT_TICKETS_VIEW"),
                    columns=[NameSelector(pattern="TICKET_DESCRIPTION")],
                    keys=[NameSelector(pattern="TICKET_ID")],
                )
            ],
        )
    ],
)
std_extractor = StandardExtractor(topics=topics)

extraction = Extraction(
    extractor=PipelineExtractor(steps=[src_extractor, std_extractor]),
    output=Output(db_schema="MY_SCHEMA"),
    defaults=Defaults(parallelism_per_node=1, batch_size=10),
)
extraction.run(my_secrets)
```

### Branch Extraction

Use this when the workflow should fan out into multiple extractor branches from
the same source data.

Pattern:

- define one shared source step
- branch into multiple extractors that should run from the same source rows
- use this when one preprocessing flow should produce several TXAIE result
  objects in parallel

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
    name="DOCUMENTS",
    sources=[
        SchemaSource(
            db_schema=NameSelector(pattern="MY_SCHEMA"),
            tables=[
                TableSource(
                    table=NameSelector(pattern="CUSTOMER_SUPPORT_TICKETS_VIEW"),
                    columns=[NameSelector(pattern="TICKET_DESCRIPTION")],
                    keys=[NameSelector(pattern="TICKET_ID")],
                )
            ],
        )
    ],
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

## Step 4: Query the Generated Tables and Views

The Text AI notebooks do not stop at `extraction.run(...)`. They query the
generated tables and views directly to inspect results and build analytics on
top of them.

The exact object names depend on the extractor shape and the source objects
used in the workflow, but the notebooks show these general result patterns:

- `DOCUMENTS` for the normalized source-document table with span identifiers
- `DOCUMENTS_<SOURCE_VIEW_NAME>_VIEW` for the source data plus the generated text span keys
- `TOPIC_CLASSIFIER_VIEW` for topic-classifier output
- `NAMED_ENTITY_VIEW` for named entities
- `KEYWORD_SEARCH_VIEW` for keywords
- `TXAIE_AUDIT_LOG` for run-level logging

When the workflow uses `StandardExtractor`, notebook-connector workflows can
also produce and query:

- `TOPICS_VIEW` for topic rows joined in a form used by later analytics queries
- `CO_OCCURRENCE` for rows that combine topic, named-entity, and keyword hits
  found in the same document span, which makes it useful for downstream
  correlation or co-mention analysis

Typical inspection flow from the notebooks:

```sql
SELECT TABLE_SCHEMA, TABLE_NAME
FROM EXA_ALL_TABLES
WHERE TABLE_SCHEMA = 'MY_SCHEMA';
```

```sql
SELECT VIEW_SCHEMA, VIEW_NAME
FROM EXA_ALL_VIEWS
WHERE VIEW_SCHEMA = 'MY_SCHEMA';
```

```sql
DESC "MY_SCHEMA".DOCUMENTS;
SELECT * FROM "MY_SCHEMA".DOCUMENTS WHERE TEXT_DOC_ID < 5;
```

```sql
DESC "MY_SCHEMA".TOPIC_CLASSIFIER_VIEW;
SELECT * FROM "MY_SCHEMA".TOPIC_CLASSIFIER_VIEW LIMIT 5;
```

```sql
DESC "MY_SCHEMA".NAMED_ENTITY_VIEW;
SELECT TEXT_DOC_ID, ENTITY, ENTITY_TYPE, ENTITY_SCORE
FROM "MY_SCHEMA".NAMED_ENTITY_VIEW
LIMIT 5;
```

```sql
DESC "MY_SCHEMA".KEYWORD_SEARCH_VIEW;
SELECT TEXT_DOC_ID, KEYWORD, KEYWORD_SCORE
FROM "MY_SCHEMA".KEYWORD_SEARCH_VIEW
WHERE TEXT_DOC_ID < 5;
```

The preprocessing notebook also reads the audit log after reruns:

```python
from exasol.nb_connector.connections import open_pyexasol_connection

with open_pyexasol_connection(my_secrets, compression=True) as conn:
    audit_log = conn.export_to_pandas(
        """
        SELECT
            RUN_ID,
            DB_OBJECT_NAME,
            EVENT_NAME,
            ROW_COUNT,
            LOG_TIMESTAMP
        FROM "MY_SCHEMA".TXAIE_AUDIT_LOG
        ORDER BY LOG_TIMESTAMP DESC
        LIMIT 100
        """
    )
```

If the user wants to rerun a preprocessing workflow from a clean state instead
of using the incremental behavior, the preprocessing notebook shows the helper
`delete_text_ai_preprocessing_tables()` as one way to drop generated TXAIE
tables first. This is an optional notebook-level reset pattern, not something
required by `Extraction.run(...)`.

## Step 5: Build Analytics on Top of TXAIE Results

The `txaie_analytics.ipynb` notebook shows that notebook-connector workflows
can create regular SQL views on top of TXAIE output rather than calling
additional Python wrappers.

Common analytics patterns are:

- when the workflow used `StandardExtractor`, join the source-document view
  with `TOPICS_VIEW` to derive downstream classification flags
- join the source-document view with `NAMED_ENTITY_VIEW` to aggregate extracted
  entities
- filter `CO_OCCURRENCE` when the workflow came from `StandardExtractor` and
  the user wants to analyze which topics, entities, and keywords occur
  together in the same source text
- create downstream analysis views on top of the generated TXAIE result views

A downstream analytics workflow assumes the preprocessing workflow already ran
and produced those views.

In the notebook, the source-document view name depends on the original source
view. In this skill, use a schema-qualified placeholder such as
`"MY_SCHEMA"."DOCUMENTS_<SOURCE_VIEW_NAME>_VIEW"` rather than hardcoding one
notebook-specific generated name.

Example pattern for deriving a downstream view from topic output:

```sql
CREATE OR REPLACE VIEW "MY_SCHEMA".TEXT_TOPIC_ANALYSIS AS
SELECT
    D.*,
    T.TOPIC_SCORE,
    T.TOPIC_SCORE > 0.7 AS MATCHES_TARGET_TOPIC
FROM "MY_SCHEMA"."DOCUMENTS_<SOURCE_VIEW_NAME>_VIEW" D
JOIN "MY_SCHEMA".TOPICS_VIEW T
    ON D.TEXT_DOC_ID = T.TEXT_DOC_ID
   AND D.TEXT_CHAR_BEGIN = T.TEXT_CHAR_BEGIN
   AND D.TEXT_CHAR_END = T.TEXT_CHAR_END
WHERE T.TOPIC = 'target_topic';
```

Example pattern for aggregating extracted entities:

```sql
SELECT E.ENTITY AS ENTITY_VALUE, COUNT(DISTINCT D.ROW_ID) AS ROW_COUNT
FROM "MY_SCHEMA"."DOCUMENTS_<SOURCE_VIEW_NAME>_VIEW" D
JOIN "MY_SCHEMA".NAMED_ENTITY_VIEW E
    ON D.TEXT_DOC_ID = E.TEXT_DOC_ID
   AND D.TEXT_CHAR_BEGIN = E.TEXT_CHAR_BEGIN
   AND D.TEXT_CHAR_END = E.TEXT_CHAR_END
WHERE E.ENTITY_TYPE LIKE 'target_type%'
GROUP BY E.ENTITY
ORDER BY ROW_COUNT DESC;
```

Use `CO_OCCURRENCE` only when the workflow actually produced it, which in the
notebook examples happens through `StandardExtractor`.

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

## Safety Notes

- Prefer a local license file over embedding real license content inline.
- Do not share real license content.
- Prefer local files and the secure config store for sensitive inputs.
- Do not expose real customer text or sensitive datasets in extraction
  examples.
