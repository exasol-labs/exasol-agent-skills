# /exasol-ai Command

Set up and use Exasol AI extensions and notebook-connector workflows via the notebook-connector CLI and Python API.

## Usage

```
/exasol-ai <task description>
```

## Examples

```
/exasol-ai set up the secret store
/exasol-ai configure notebook-connector for an on-prem Exasol database
/exasol-ai start the bundled notebook environment
/exasol-ai bring up a local Docker Exasol for notebook-connector
/exasol-ai open an ibis connection from the secure config store
/exasol-ai initialize the Transformers Extension
/exasol-ai upload bert-base-uncased model to BucketFS
/exasol-ai run NER on my reviews table
/exasol-ai generate embeddings for the products table
/exasol-ai initialize text ai extension with version 1.2.0
/exasol-ai start JupyterLab with the bundled notebooks
/exasol-ai what models are supported for zero-shot classification?
```

## Routing

When invoked, determine the intent and activate the appropriate skill:

1. **Setup / credentials / secret store / first-time config / notebook-connector configuration** → activate **exasol-ai-setup** skill
2. **JupyterLab / bundled notebooks / ai-lab CLI** → activate **exasol-ai-lab** skill
3. **Local Docker DB / ITDE / docker-db workflow** → activate **exasol-itde** skill
4. **notebook-connector Python connection helpers** → activate **exasol-notebook-connections** skill
5. **Transformers Extension / Hugging Face models / NLP UDFs / upload_model / TE scripts** → activate **exasol-transformers** skill
6. **Text AI Extension / TXAIE / NER / feature extraction / zero-shot / embeddings via Python API** → activate **exasol-text-ai** skill
7. **Unsure** → ask the user: *"Are you setting up notebook-connector, starting notebooks, using a local Docker Exasol, working with the Transformers Extension, or using the Text AI Extension?"*

Always check that the secret store is configured before proceeding with connection helpers or AI extension tasks. If not, run the **exasol-ai-setup** skill first.
