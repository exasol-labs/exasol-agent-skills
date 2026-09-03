# Upstream Documentation Is the Source of Truth

This skill provides **high-level direction only**: it helps the user pick the right deployment flavor and keeps the overall setup on track. It deliberately does **not** duplicate installation commands, account-setup steps, or credential details.

**The official repository is the single source of truth:**

```
https://github.com/exasol/exasol-personal
```

Once the flavor is chosen, fetch the relevant upstream documents and follow them exactly. Never reproduce commands from memory — Exasol Personal changes frequently, and stale commands break setups.

## Documents to Fetch

| Document | Fetch when |
|---|---|
| `README.md` | Always — the master instructions |
| `HOWTO_SETUP_AWS_ACCOUNT.md` | AWS cloud deployment |
| `HOWTO_SETUP_AZURE_ACCOUNT.md` | Azure cloud deployment |
| `HOWTO_SETUP_EXOSCALE_ACCOUNT.md` | Exoscale cloud deployment |
| `HOWTO_SETUP_STACKIT_ACCOUNT.md` | STACKIT cloud deployment |
| `doc/presets.md` | Custom or external presets |

Raw URL pattern:
```
https://raw.githubusercontent.com/exasol/exasol-personal/main/<document>
```

## When a Fetch Fails

If the host is unreachable, the network is restricted, or the document has
moved — do not improvise the missing steps from memory, and do not fall back to
the outdated commands you may recall. Tell the user which document could not be
retrieved and why, then offer to either retry, or have them open the document
themselves and paste the relevant section:

```
https://github.com/exasol/exasol-personal/blob/main/<document>
```

Only the launcher-state commands this skill names directly (`exasol version`, `exasol info`, `exasol connect`, `exasol deployments list`, `exasol diag local`) are safe to run without the upstream docs; anything that installs, provisions, or destroys is not.

## Running SQL During Setup

**Use the launcher's built-in SQL client, `exasol connect`, for every SQL statement and script this skill executes — never `exapump`.**

`exasol connect` is part of the launcher the user just installed, reads its credentials from the deployment directory automatically, and works identically for local and cloud deployments. Requiring an exapump profile mid-setup adds a second tool and a second set of credentials before the database is even verified.

```bash
exasol connect                          # interactive shell
exasol connect -c "SELECT 1"            # inline statement(s), ';'-separated
exasol connect -f script.sql            # run a script file
exasol connect -d <name> -c "SELECT 1"  # target a named deployment
exasol connect --csv -c "SELECT * FROM PRODUCTS" > products.csv
```

Non-interactive runs (`-c` / `-f`) stop at the first failing statement and exit non-zero, so use them when you need to detect errors. Add `--json` for machine-readable output.

This skill never installs or configures `exapump`.
