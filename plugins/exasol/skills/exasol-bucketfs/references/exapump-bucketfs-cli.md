# The `exapump bucketfs` CLI

The `exapump` command is the CLI tool for managing BucketFS. All BucketFS operations use the `exapump bucketfs` subcommand.

## Connection Configuration

Connection settings are stored in `~/.exapump/config.toml` as named profiles. Example:

```toml
[production]
host = "exasol-prod.example.com"
user = "admin"
password = "<database-password>"
default = true
bfs_write_password = "<bucketfs-write-password>"
bfs_read_password = "<bucketfs-read-password>"
```

Key profile fields:

| Field | Default | Purpose |
|-------|---------|---------|
| `bfs_host` | Falls back to `host` | BucketFS hostname |
| `bfs_port` | `2581` | BucketFS port |
| `bfs_bucket` | `default` | Bucket name |
| `bfs_write_password` | Required | Write authentication |
| `bfs_read_password` | Falls back to write password | Read authentication |
| `bfs_tls` | Falls back to `tls` | Enable TLS |
| `bfs_validate_certificate` | Falls back to `validate_certificate` | Certificate validation |

Connection parameters can also be overridden per command via CLI flags (highest priority):

| Flag | Purpose |
|------|---------|
| `--profile` | Select a named profile |
| `--bfs-host` | Override hostname |
| `--bfs-port` | Override port |
| `--bfs-bucket` | Override bucket name |
| `--bfs-write-password` | Override write password |
| `--bfs-read-password` | Override read password |
| `--bfs-tls` | Override TLS setting |
| `--bfs-validate-certificate` | Override certificate validation |

**Parameter resolution order:** CLI flags → profile values → smart defaults.

## Configuration Protocol

**Before any BucketFS operation**, verify the connection is configured:

1. Check if `~/.exapump/config.toml` exists and contains a default profile.
2. If configured, proceed with the operation.
3. If not configured, explain which host, port, bucket, and credential fields
   are required, then have the user enter secrets locally through
   `exapump profile add <name>` or their secure configuration workflow. Do not
   ask them to paste passwords into chat, guess values, or echo secret values.

## `ls` — List Contents

```bash
exapump bucketfs ls [PATH] [OPTIONS]
exapump bucketfs ls -r [PATH]            # Recursive listing
exapump bucketfs ls --recursive [PATH]
```

**Examples:**
```bash
exapump bucketfs ls                      # List bucket root
exapump bucketfs ls models/             # List a directory
exapump bucketfs ls -r models/          # Recursively list all files under models/
```

## `cp` — Copy / Upload / Download

Direction is automatically determined by the source type (local file vs. BucketFS path).

Upload a local file to BucketFS:
```bash
exapump bucketfs cp <local-file> <bucket-path>
exapump bucketfs cp <local-file> <bucket-dir>/    # Preserve filename
```

Download a file from BucketFS to local:
```bash
exapump bucketfs cp <bucket-path> <local-path>
```

**Examples:**
```bash
exapump bucketfs cp my_model.pkl models/my_model.pkl     # Upload with explicit name
exapump bucketfs cp my_model.pkl models/                 # Upload, preserve filename
exapump bucketfs cp library.jar jars/library.jar         # Upload JAR for UDF
exapump bucketfs cp models/my_model.pkl .                # Download to current dir
exapump bucketfs cp models/my_model.pkl ./local-copy.pkl # Download with rename
```

## `rm` — Remove a File

```bash
exapump bucketfs rm <path-in-bucket>
```

**Examples:**
```bash
exapump bucketfs rm models/old_model.pkl     # Delete a single file
```

## Safety

Before running `rm`, show the exact bucket, path, and profile, then obtain
explicit confirmation. Before a `cp` that would overwrite an existing
BucketFS or local file, inspect the target and obtain confirmation. Never print
profile passwords or pass them as command-line arguments when a profile can
hold them securely.
