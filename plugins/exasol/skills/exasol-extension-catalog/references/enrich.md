# ENRICH Catalog

Use ENRICH when the user wants AI, ML, UDFs, text analytics, semantic interpretation, agents, or custom computation.

Support-level shorthand:

- Exasol-owned or Exasol-maintained: official Exasol docs and `github.com/exasol/...`.
- Exasol Labs/community: `github.com/exasol-labs/...`; verify the README and release status before production recommendations.
- Third-party ecosystem: vendor-owned tools and services documented by Exasol; verify vendor support details.

Version-specific notes are source-check reminders. Verify linked release notes or download pages before quoting current versions.

## AI Lab

- **Use for**: packaged AI/ML notebook workflows and prebuilt images for AI experimentation.
- **Best when**: user wants examples for ML, transformers, notebooks, SLCs, or data science on Exasol.
- **Direction of travel**: AI Lab now builds on Notebook Connector, the SageMaker notebooks have been removed, and Docker images, AMIs, and VM images are published from the release page. Read the releases index below for the current release.
- **Links**:
  - https://github.com/exasol/ai-lab
  - https://github.com/exasol/ai-lab/releases
  - https://docs.exasol.com/db/latest/ai/ai_get_started/set-up-ai-lab.htm

## Text AI Extension

- **Use for**: text analytics via Exasol SQL UDFs.
- **Best when**: user wants named entity recognition, information extraction, summarization, or keyword extraction.
- **Links**:
  - https://docs.exasol.com/db/latest/ai/ai_application/extract-insights-from-text.htm

## Transformers Extension

- **Use for**: Hugging Face Transformers in Exasol workflows and built-in AI UDFs.
- **Best when**: user wants pretrained transformer inference near the database, sentiment analysis, classification, entity extraction, or more configurable extended prediction UDFs.
- **Breaking change in 4.0.0**: introduced `AI_SENTIMENT`, `AI_CLASSIFY`, and `AI_EXTRACT_ENTITIES`, renamed existing prediction UDFs, and changed model task-type handling. Treat an upgrade across it as breaking and point users at the migration and release docs.
- **Links**:
  - https://github.com/exasol/transformers-extension
  - https://github.com/exasol/transformers-extension/releases/tag/4.0.0
  - https://github.com/exasol/transformers-extension/blob/main/doc/user_guide/user_guide.md
  - https://pypi.org/project/exasol-transformers-extension/

## SageMaker Extension

- **Use for**: AWS SageMaker integration with Exasol data.
- **Best when**: user wants to train or invoke SageMaker workflows using Exasol data.
- **Links**:
  - https://github.com/exasol/sagemaker-extension
  - https://pypi.org/project/exasol-sagemaker-extension/

## MLflow Plugin and MLflow server

- **Use for**: MLflow REST API access and model-serving integration.
- **Best when**: user wants to query MLflow REST APIs from Exasol SQL or use MLflow AI Gateway/model serving.
- **Links**:
  - https://github.com/exasol/mlflow-plugin
  - https://exasol.github.io/mlflow-plugin/main/
  - https://github.com/exasol-labs/exasol-labs-mlflow-server

## In-database ML model UDFs

- **Use for**: running models directly inside Exasol via UDFs.
- **Best when**: user wants parallel model inference close to data and minimal data movement.
- **Links**:
  - https://docs.exasol.com/db/latest/ai/ai_connect_models/in-database-models.htm

## Foundation model integrations

- **Use for**: calling external LLM/foundation model APIs.
- **Best when**: user wants OpenAI, Anthropic, Google, or other HTTP model APIs from Exasol UDFs, external scripts, or MCP tools.
- **Links**:
  - https://docs.exasol.com/db/latest/ai/ai_connect_models/foundation-models.htm

## Agent Control Plane pattern

- **Use for**: database-native agent governance and orchestration.
- **Best when**: user wants multi-agent systems with agent registry, prompts, schemas, model catalog, runs, call logs, cost tracking, credentials, and UDF orchestration.
- **Links**:
  - https://www.exasol.com/blog/exasol-agent-control-plane/

## Python Extension Common

- **Use for**: common Python extension utilities used by Python-based Exasol extensions.
- **Best when**: building or maintaining Python-based Exasol extensions.
- **Links**:
  - https://github.com/exasol/python-extension-common
  - https://pypi.org/project/exasol-python-extension-common/

## UDF API Java

- **Use for**: compiling Java UDFs against the Exasol UDF API.
- **Best when**: user wants Java-based UDF development.
- **Links**:
  - https://github.com/exasol/udf-api-java

## language-container-rs

- **Use for**: writing Exasol UDFs in Rust.
- **Best when**: user wants Rust-native UDFs compiled to `.so` libraries, uploaded to BucketFS, and registered as a `RUST` script language.
- **Support note**: Exasol Labs project; early-stage but functional in tests according to product-news announcement. Verify current README before using in customer-facing production guidance.
- **Links**:
  - https://github.com/exasol-labs/language-container-rs

## Metadata Agent

- **Use for**: AI-generated schema documentation.
- **Best when**: user wants to enrich metadata and documentation automatically.
- **Links**:
  - https://github.com/exasol-labs/metadata-agent
  - https://docs.exasol.com/db/latest/ai/ai_application/index.htm

## AI Process Mining demonstrator

- **Use for**: AI-driven analysis of process bottlenecks from event logs.
- **Best when**: user wants example AI applications on top of Exasol analytics.
- **Links**:
  - https://docs.exasol.com/db/latest/ai/ai_application/ai-process-mining.htm
  - https://github.com/exasol-labs/exasol-labs-ai-process-mining

## ML ecosystem tools

Use these when the user wants external ML platforms connected to Exasol:

- DataRobot: https://www.datarobot.com/
- Dataiku: https://www.dataiku.com/
- H2O.ai: https://h2o.ai/
- KNIME: https://www.knime.com/
- RapidMiner / Altair AI Studio: https://altair.com/altair-ai-studio
- IBM SPSS Modeler: https://www.ibm.com/products/spss-modeler
- Zingg: https://github.com/zinggAI/zingg
- Ecosystem overview: https://docs.exasol.com/db/latest/connect_exasol/ecosystem_overview.htm
