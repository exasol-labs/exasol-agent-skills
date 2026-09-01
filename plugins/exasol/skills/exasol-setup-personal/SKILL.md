---
name: exasol-setup-personal
description: "Guided setup of Exasol Personal — a free Exasol database running locally on a Mac or deployed to your own AWS, Azure, Exoscale, or STACKIT account. Covers picking the right deployment flavor, the `exasol` launcher CLI (`exasol install <preset>`, `exasol connect`, `exasol info`, `exasol deployments list`, `exasol destroy`), the `local`, `aws`, `azure`, `exoscale`, and `stackit` presets, and following the official exasol/exasol-personal instructions."
---

# Exasol Personal Setup Skill

Trigger when the user mentions **Exasol Personal**, **setup Exasol**, **deploy Exasol**, **install Exasol**, **personal database**, **Exasol locally**, **Exasol on AWS/Azure/Exoscale/STACKIT**, or asks to **get started with Exasol**.

## How This Skill Works

This skill provides **high-level direction only**: it helps the user pick the right deployment flavor and keeps the overall setup on track. It deliberately does **not** duplicate installation commands, account-setup steps, or credential details.

**The official repository is the single source of truth:**

```
https://github.com/exasol/exasol-personal
```

Once the flavor is chosen, fetch the relevant upstream documents and follow them exactly. Never reproduce commands from memory — Exasol Personal changes frequently, and stale commands break setups.

Upstream documents to fetch (raw URLs, `main` branch):

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

**If a fetch fails** — the host is unreachable, the network is restricted, or the document has moved — do not improvise the missing steps from memory, and do not fall back to the outdated commands you may recall. Tell the user which document could not be retrieved and why, then offer to either retry, or have them open the document themselves and paste the relevant section:

```
https://github.com/exasol/exasol-personal/blob/main/<document>
```

Only the launcher-state commands this skill names directly (`exasol version`, `exasol info`, `exasol connect`, `exasol deployments list`, `exasol diag local`) are safe to run without the upstream docs; anything that installs, provisions, or destroys is not.

Ask the user explicitly at every question, confirmation, and decision point.
Use the host agent's structured user-input mechanism when one is available;
otherwise ask a concise question in the conversation. Never assume answers or
skip required confirmations. This instruction applies equally to Claude Code
and OpenAI Codex.

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

This skill never installs or configures `exapump`. After setup, use
**exasol-import** for local uploads, **exasol-export** for local exports, and
**exasol-database** for general SQL or exapump profile work.

---

## Phase 0: Introduction

Explain what Exasol Personal is:

A full Exasol analytics database — in-memory, columnar, MPP — free for personal use. It runs either **locally on your Mac** or **in your own cloud account**. The `exasol` launcher CLI handles install, start/stop, connect, and destroy.

Then explain the two flavors:

**Local (macOS only, fastest)**
- Runs in a VM on the user's Mac, starts in seconds
- No cloud account, no credentials, no cost
- Requires macOS 15 (Sequoia) or later and at least 8 GB RAM
- Limitations: no script language container preinstalled (install one with `exasol slc install <language>` to enable UDFs), no virtual schemas yet, no Admin UI yet, always single-node

**Cloud (AWS, Azure, Exoscale, STACKIT)**
- Runs on provisioned compute in the user's own cloud account
- Needed for: multi-node clusters, virtual schemas, the Admin UI, a shared instance, or any non-macOS host
- Requires a cloud account with permission to provision compute instances, plus per-provider credentials
- Deployment takes roughly 10–20 minutes and incurs cloud costs

Ask: **"Ready to get started?"**

---

## Phase 1: Choose the Deployment Flavor

First detect the platform:

```bash
uname -s
sw_vers                       # macOS only — check version is 15 or later
sysctl -n hw.memsize          # macOS only — check at least 8 GB
```

Then ask which flavor they want, tailoring the recommendation:

- **On macOS 15+ with at least 8 GB RAM:** offer **Local** as the first, recommended option, with AWS, Azure, and the other cloud providers as alternatives. Recommend local unless the user needs something local does not yet support (multi-node, virtual schemas, Admin UI, or a shared instance) — ask about those needs if it is unclear.
- **On macOS below 15, or with less than 8 GB RAM:** explain local is not supported on this machine and offer the cloud providers.
- **On Linux or Windows:** explain local deployment is macOS-only today (Windows and Linux support is coming) and offer the cloud providers.

If the user picks a cloud provider, confirm which one: AWS, Azure, Exoscale, or STACKIT.

Record the chosen flavor — it selects the `exasol install <preset>` preset name (`local`, `aws`, `azure`, `exoscale`, `stackit`). The preset name alone is not always a complete command: some providers require additional flags, listed in Phase 3.

---

## Phase 2: Install the Exasol Launcher

Check whether the launcher is already installed:

```bash
exasol version
```

If it is not installed, fetch the upstream `README.md` and follow its **Install the Launcher** section for the user's platform. Verify with `exasol version` afterwards; if the command is not found, the user may need a new terminal or a `PATH` adjustment as described by the installer output.

---

## Phase 3: Flavor-Specific Setup

### If Local

Fetch the upstream `README.md` and follow its **Quick Start — Run Exasol Locally** section.

Before installing, ask whether the user wants the default deployment or a named one (`-d <name>`), explaining that named deployments let several databases run side by side. Follow the README's **Deployments and Named Deployments** section.

If the user wants to run UDFs, follow the README's **UDFs and Script Language Containers** section to install the needed script language container — local deployments ship without one.

### If Cloud

1. Fetch the provider's `HOWTO_SETUP_<PROVIDER>_ACCOUNT.md` from the upstream repo and walk the user through it step by step, waiting for confirmation at each step. This covers account preparation, permissions, and the credentials or environment variables the launcher expects.
2. Confirm credentials are in place before deploying.
3. **Collect every install option before running anything** — all of the options below are install-time only and cannot be changed afterwards without destroying and reinstalling. In one round of questions, gather:
   - **Any flags the provider requires** (see the table below) — the install fails without them.
   - **Cluster size and instance type**, or the defaults (README section **Cloud: Choosing cluster size and compute instance types**).
   - **A named deployment** (`-d <name>`), or the default.
4. Fetch the upstream `README.md`, follow its **Deploy to the Cloud** section, and run `exasol install <preset>` with the options collected in step 3.

**Per-provider install flags** — confirm these against the provider's HOWTO, which is authoritative:

| Provider | Required | Optional |
|---|---|---|
| `aws` | none — region comes from the AWS CLI profile | |
| `azure` | `--location <region>` — the target region is **not** inferred | |
| `exoscale` | none | `--zone <zone>` (defaults to `ch-gva-2`) |
| `stackit` | `--project-id <uuid>` | `--region <region>` (defaults to `eu01`) |

The README's **Deploy to the Cloud** section shows bare `exasol install <preset>` commands for readability. For Azure and STACKIT those are incomplete — always add the required flag.

Tell the user cloud deployment takes about 10–20 minutes and must not be interrupted — an interrupted install can leave billable resources behind that need `exasol destroy` or manual cleanup.

---

## Phase 4: Verify and Connect

Follow the upstream `README.md` **Next steps** section:

- Run `exasol info` for connection details and the Admin UI URL (cloud only).
- Credentials live in `secrets.json` in the deployment directory.
- Test with the built-in SQL client: `exasol connect -c "SELECT 1"`.

Also tell the user about lifecycle commands from the README:
- `exasol stop` / `exasol start` — pause and resume (cloud: networking and storage keep costing; IPs change on restart)
- `exasol deployments list` — see all deployments and their status
- `exasol destroy` — remove the deployment and all its data; **never** delete a deployment directory without destroying first

---

## Phase 5: Load Sample Data (Optional)

Ask: **"Would you like to load sample data? This adds a PRODUCTS table (1M rows) and a PRODUCT_REVIEWS table (1.8M rows) you can query right away."**

If yes, follow the upstream `README.md` **Load Sample Data** section, running the statements with `exasol connect` (`-f sample.sql` from the deployment directory, or `-c` with the SQL inline).

Verify the load with `exasol connect`:

```bash
exasol connect -c "SELECT COUNT(*) FROM PRODUCTS; SELECT COUNT(*) FROM PRODUCT_REVIEWS"
```

Compare the results against the row counts in the README's **Load Sample Data** table, which you already fetched — do not rely on counts quoted from memory.

---

## Phase 6: Hand Off

Tell the user they can now use `/exasol` or just describe what they want in natural language. Suggest concrete next steps:

- **Query the data** — "show me the top 10 products by price", "how many reviews per product category?"
- **Load their own data** — CSV or Parquet files into new tables
- **Explore the schema** — list schemas, tables, and columns
- **Run UDFs** — on local deployments, install a script language container first

The shared Exasol router activates **exasol-database** for SQL and general
exapump work, **exasol-import** or **exasol-export** for data movement,
**exasol-bucketfs** for BucketFS, and **exasol-udfs** for UDF/SLC work.

---

## Troubleshooting

Do not improvise fixes. Fetch the upstream documentation first:

- **Local deployment misbehaving:** run `exasol diag local` for a JSON snapshot of VM status, guest IP, bound ports, and database readiness (README, **Start and stop Exasol Personal**).
- **Interrupted or failed cloud install:** rerun `exasol install <preset>` with the same presets to retry safely, or `exasol destroy` to clean up (README, **Deployments and Named Deployments**).
- **Cached runtime artifacts:** `exasol cache list`, `exasol cache clean`, `exasol diag cache`.
- **Anything else:** re-read the relevant upstream section, or point the user at the [Exasol Community](https://community.exasol.com) using the `exasol-personal` tag.
