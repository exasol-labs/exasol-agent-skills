---
name: exasol-setup-local
description: Guided setup of Exasol Local (a.k.a. Exasol Nano) — a single-node Exasol database that runs locally on the user's machine. Covers launcher installation, deployment to ~/.exasol/deployments/default, and running queries with the built-in `exasol connect` command. This is the local flavor of Exasol Personal; for the cloud-hosted variant see the exasol-setup-personal skill.
---

# Exasol Local Setup Skill

Trigger when the user asks to **set up**, **install**, **deploy**, or **get started with** any of: **Exasol Local**, **Exasol Personal Local**, **Exasol Nano**, or the **local flavor of Exasol Personal**.

This skill is the local-machine counterpart to `exasol-setup-personal`. The cloud-deployed flavor (AWS) is covered there; everything in this skill runs on the user's own machine — no cloud account or AWS CLI needed.

**Always use the `AskUserQuestion` tool for every confirmation and decision point — no exceptions. Never assume answers or skip questions.**

Guide the user through each phase below in order. Do not skip phases — each depends on the previous one.

---

## Phase 0: Introduction

Briefly tell the user what this skill will do:

1. Install the `exasol` launcher binary into `~/.local/bin`
2. Create the deployment directory `~/.exasol/deployments/default`
3. Run `exasol install local` and wait for the database to come up
4. Verify the deployment files were written
5. Test the connection with `SELECT 1` using the built-in `exasol connect` command

Queries against the local database are run with `exasol connect`, **not** `exapump`. The `exasol connect` command reads the deployment's connection details and credentials directly from the deployment directory, so there is no separate profile to create.

Use `AskUserQuestion` to ask: **"Ready to get started?"**

---

## Phase 1: Install the Launcher

### Step 1: Ensure `~/.local/bin` exists

```bash
mkdir -p ~/.local/bin
```

### Step 2: Download the launcher

```bash
curl -fSL https://exasol-launcher.s3.eu-central-1.amazonaws.com/exasol -o ~/.local/bin/exasol
chmod +x ~/.local/bin/exasol
```

### Step 3: Verify the binary is on PATH

```bash
which exasol
exasol --help
```

If `which exasol` returns nothing, `~/.local/bin` is not on the user's PATH. Tell the user to add it by appending the following line to their shell rc file (`~/.zshrc` for zsh, `~/.bashrc` for bash) and opening a new terminal:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then re-verify before continuing. Do not proceed to Phase 2 until `exasol --help` runs successfully.

---

## Phase 2: Create the Deployment Directory

```bash
mkdir -p ~/.exasol/deployments/default
cd ~/.exasol/deployments/default
```

If the directory already contains files (e.g., a previous deployment), use `AskUserQuestion` to ask whether the user wants to reuse the existing deployment or start fresh. **Never delete files in this directory without explicit confirmation.**

All `exasol` commands in the following phases must be run from this directory.

---

## Phase 3: Deploy the Local Database

From `~/.exasol/deployments/default`, run:

```bash
exasol install local
```

Tell the user:
- This runs entirely on their local machine — no cloud resources are provisioned.
- Wait for the command to finish. It will print connection details (host, port, "database is up" or similar) when ready.
- Do not interrupt the process.

When the command finishes, verify the deployment files exist:

```bash
ls ~/.exasol/deployments/default
```

Both `deployment.json` and `secrets.json` should be present.

---

## Phase 4: Verify the Deployment

The deployment writes its files into `~/.exasol/deployments/default`. Confirm the key files are present:

```bash
ls ~/.exasol/deployments/default
```

`deployment.json` (connection metadata) and `secrets.json` (credentials) should both exist.

You do **not** need to read these files to connect. The `exasol connect` command (Phase 5) reads the host, port, username, and password from the deployment directory automatically — including the dynamic port, which changes on every redeployment. **Never print the SYS password to the chat or write it into any file or message in plain text.**

---

## Phase 5: Run Queries with `exasol connect`

Queries against the local database are executed with `exasol connect`, **not** `exapump`. There is no profile to set up — `exasol connect` discovers the running deployment in `~/.exasol/deployments/default` and connects automatically.

### The interactive-shell gotcha

Run with no input, `exasol connect` opens an **interactive SQL shell** and waits for keystrokes — it will hang in an automated context. To execute statements non-interactively, **feed them in via stdin** using input redirection (`<`) or a pipe.

### How to run a query

Use a here-string / heredoc with `<`, or pipe with `printf`. Always run from the deployment directory:

```bash
cd ~/.exasol/deployments/default

# Heredoc via stdin redirection (preferred for multi-line SQL)
exasol connect <<'SQL'
SELECT 1;
SQL

# Or pipe a single statement
printf 'SELECT 1;\n' | exasol connect
```

Notes:
- Each statement must be terminated with a semicolon `;`. Multiple statements can be fed in one invocation.
- Add `--json=compact` (or `--json` for pretty) when you need machine-readable output to parse:
  ```bash
  printf 'SELECT 1 AS n;\n' | exasol connect --json=compact
  ```
- `exasol connect` defaults to user `sys` and reads the password from the deployment directory; do not pass credentials on the command line.

---

## Phase 6: Test the Connection

Run a `SELECT 1` to confirm everything works:

```bash
cd ~/.exasol/deployments/default
printf 'SELECT 1;\n' | exasol connect
```

If it returns `1`, setup is complete. Tell the user:
- Run queries against the local database with `exasol connect` (feeding SQL via `<` or a pipe), **not** `exapump` — no profile setup is required.
- All `exasol` commands must be run from `~/.exasol/deployments/default`.
- Because `exasol connect` reads connection details live from the deployment directory, a redeployment (`exasol install local`) needs no reconfiguration — the new port is picked up automatically.

If `SELECT 1` fails, verify the database is running with `exasol status` (run from the deployment directory) and retry.

---

## Phase 7: Wrap Up

Tell the user setup is complete and summarize what is available:

- The local database is running; query it with `exasol connect` (feeding SQL via `<` or a pipe) from `~/.exasol/deployments/default`.
- The **exasol-database**, **exasol-bucketfs**, and **exasol-udfs** skills are available for working with the database.

---

## Related Skills

- **exasol-setup-personal** — the cloud-deployed (AWS) flavor of Exasol Personal.
- **exasol-database** — SQL behavior, IMPORT/EXPORT, table design. Note: this skill's examples use the `exapump` CLI; for the local database run the SQL with `exasol connect` (feeding statements via `<` or a pipe) instead.
- **exasol-bucketfs** — BucketFS file management.
- **exasol-udfs** — UDFs and Script Language Containers.
