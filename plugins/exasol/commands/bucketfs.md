---
description: Compatibility shortcut for Exasol BucketFS file-management tasks.
---

# /bucketfs Command

Compatibility shortcut for BucketFS-specific tasks. Prefer
`/exasol bucketfs <task>` in user-facing examples.

## Usage

```text
/bucketfs <BucketFS task or question>
```

## Behavior

1. Treat the complete request as an Exasol BucketFS request and activate the
   shared top-level **exasol** skill.
2. Follow the top-level router into **exasol-bucketfs**, then follow that
   skill's connection, command, validation, and safety guidance.

## Examples

```text
/bucketfs list all files in the bucket
/bucketfs upload my_model.pkl to models/my_model.pkl
/bucketfs download jars/library.jar to ./lib/
/bucketfs delete models/old_model.pkl
```
