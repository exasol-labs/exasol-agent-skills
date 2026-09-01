---
description: Route any Exasol task through the shared top-level Exasol skill.
---

# /exasol Command

Unified Claude Code entry point for Exasol work.

## Usage

```text
/exasol <Exasol task, SQL query, or question>
```

## Behavior

1. Activate the top-level **exasol** skill for the complete user request.
2. Choose the narrowest specialized skill whose front-matter description
   matches the request, then apply the router's precedence rules, dependency
   order, user interaction rules, and safety rules. The top-level skill is the
   single source of truth; do not duplicate or reinterpret its rules here.
3. Follow the selected specialized skill, including its prerequisites,
   validation, safety rules, and handoffs to related skills.
4. Do not ask the user to select an internal skill. If the outcome is
   ambiguous, ask one concrete question about the desired result.

## Examples

```text
/exasol SELECT COUNT(*) FROM my_schema.my_table
/exasol upload sales_data.csv to analytics.sales
/exasol export the users table to CSV in S3
/exasol create a PostgreSQL JDBC virtual schema
/exasol build a custom virtual schema adapter for a new JDBC dialect
/exasol list BucketFS files under models/
/exasol which Exasol connector should I use for Databricks?
/exasol initialize the Text AI Extension for notebook-connector
/exasol write a Python UDF that normalizes product names
/exasol set up Exasol Personal on AWS
```
