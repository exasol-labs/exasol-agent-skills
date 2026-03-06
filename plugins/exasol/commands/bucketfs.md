# /bucketfs Command

Manage files in Exasol BucketFS using the `exapump` CLI tool.

## Usage

```
/bucketfs <task description or exapump command>
```

## Arguments

The argument can be either:
- A **direct exapump command**: `/bucketfs exapump bucketfs ls -r`
- A **task description**: `/bucketfs upload model.pkl to the models directory`
- A **question about BucketFS**: `/bucketfs what files are in the jars directory?`

## Behavior

When invoked:

0. **Verify connection configuration** before doing anything else:
   - Check if `~/.exapump/config.toml` exists and contains a default profile.
   - If configured, proceed.
   - If not configured, **ask the user** for the required connection details (host, port, bucket, passwords). Do not guess or assume any defaults. Help the user create a profile in `~/.exapump/config.toml` before continuing.

1. **Identify the task type**:
   - If the argument contains or implies an `exapump bucketfs` command (`ls`, `cp`, `rm`) — build and execute it directly.
   - If it is a natural language task description — translate it to the appropriate `exapump bucketfs` command(s) and execute.

2. **List files or directories** — use `exapump bucketfs ls`:
   - Use `exapump bucketfs ls <path>` to list a specific directory.
   - Use `exapump bucketfs ls -r <path>` for a recursive listing.
   - Use `exapump bucketfs ls` to list the bucket root.

3. **Upload a file or directory** — use `exapump bucketfs cp`:
   - Single file: `exapump bucketfs cp <local-file> <bucket-path>`
   - Preserve filename: `exapump bucketfs cp <local-file> <bucket-dir>/`
   - Direction is auto-detected from the source type.

4. **Download a file** — use `exapump bucketfs cp` in reverse:
   - `exapump bucketfs cp <bucket-path> <local-destination>`

5. **Delete a file** — use `exapump bucketfs rm`:
   - `exapump bucketfs rm <path-in-bucket>`
   - **Always confirm with the user before executing a delete operation.**

6. **On errors**:
   - Check that the path exists with `exapump bucketfs ls <path>`.
   - For permission errors, verify that `bfs_write_password` / `bfs_read_password` are set correctly in `~/.exapump/config.toml`.
   - For TLS errors, check `bfs_tls` and `bfs_validate_certificate` in the profile.
   - Connection settings can be overridden per command via `--bfs-host`, `--bfs-port`, `--bfs-bucket`, `--profile`, etc.

## Examples

```
/bucketfs list all files in the bucket
/bucketfs exapump bucketfs ls -r models/
/bucketfs upload my_model.pkl to models/my_model.pkl
/bucketfs download jars/library.jar to ./lib/
/bucketfs delete models/old_model.pkl
/bucketfs what files are under the jars folder?
```
