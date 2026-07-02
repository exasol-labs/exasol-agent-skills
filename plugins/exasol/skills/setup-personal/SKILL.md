---
name: exasol-setup-personal
description: Guided setup of Exasol Personal — a single-node Exasol database deployed to your own cloud account. Covers AWS account preparation, CLI installation, deployment, sample data loading, and MCP server setup.
---

# Exasol Personal Setup Skill

Trigger when the user mentions **Exasol Personal**, **setup Exasol**, **deploy Exasol**, **install Exasol**, **personal database**, **Exasol on AWS**, or asks to **get started with Exasol**.

**Always use the `AskUserQuestion` tool for every question, confirmation, and decision point throughout this skill — no exceptions. Never assume answers or skip questions.**

Guide the user through each phase below in order. Do not skip phases — each depends on the previous one.

For each phase, use your knowledge or research to provide current, accurate steps. Do not make up commands or URLs you are not confident about — if unsure, search for the official documentation.

---

## Phase 0: Introduction

Begin by explaining what Exasol Personal is and what this skill will do.

Tell the user:

**What is Exasol Personal?**

Exasol Personal is a single-node Exasol database deployed entirely to your own cloud account. Exasol is an analytics-optimised, in-memory columnar database built for high-performance SQL — it's the same technology used by large enterprises, now available for personal use. Key benefits:

- **Blazing fast analytics** — columnar storage and in-memory processing make complex queries over millions of rows run in seconds
- **Your own infrastructure** — the database runs on your AWS account; you own the data and control the costs
- **Full SQL compatibility** — standard SQL with powerful Exasol extensions like DISTRIBUTE BY, window functions, and UDFs
- **Simple CLI** — the `exasol` CLI handles provisioning, deployment, and management with a single command
- **Built-in SQL client** — connect and query immediately with `exasol connect`, no additional tooling required

**What this skill will do:**

This skill guides you step by step through the complete setup:
1. Prepare your AWS account and IAM permissions
2. Install and configure the AWS CLI
3. Install the `exasol` CLI
4. Deploy your Exasol database to AWS (takes 10–20 minutes)
5. Set up `exapump` for SQL execution and data loading
6. Optionally load sample data to explore

Use `AskUserQuestion` to ask: **"Ready to get started?"**

---

## Phase 1: Cloud Provider Selection

Use `AskUserQuestion` to ask which cloud provider they want to use. Currently only **AWS** is supported. If they choose anything else, explain that only AWS is available at this time and use `AskUserQuestion` to ask if they want to proceed with AWS.

---

## Phase 2: AWS Account Setup

Use `AskUserQuestion` to ask: **"Do you already have an AWS account with permissions to launch EC2 instances (specifically r6i.xlarge), or do you need to set one up?"** There's no recommended option.

### If they need to set up an AWS account:

Walk them through these steps one by one, waiting for confirmation at each step before moving on.

#### Step 1: Create an AWS account

Guide the user through creating an AWS account. Use your knowledge of the AWS sign-up process to provide current steps, or research the official AWS documentation if needed.

#### Step 2: Create the IAM policy

This policy grants Exasol Personal the exact permissions it needs — no more, no less.

Fetch the policy JSON from:
```
https://raw.githubusercontent.com/exasol/exasol-personal/refs/heads/main/assets/infrastructure/aws/iam-policy.broad.json
```

Then guide the user through creating an IAM policy in the AWS console using that JSON. Use your knowledge of the AWS IAM console to provide current navigation steps, naming the policy `ExasolPersonalPolicy`.

Use `AskUserQuestion` to confirm the policy was created before continuing.

#### Step 3: Create a dedicated IAM user

Guide the user through creating an IAM user named `exasol-personal` in the AWS IAM console, attaching the `ExasolPersonalPolicy` directly to that user. Use your knowledge of the AWS IAM console to provide current steps.

Use `AskUserQuestion` to confirm the user was created before continuing.

#### Step 4: Create access keys

Guide the user through creating CLI access keys for the `exasol-personal` IAM user in the AWS IAM console. Use your knowledge of the AWS IAM console to provide current steps.

Make sure the user saves both values — the Secret Access Key is shown only once:
- **Access Key ID** (starts with `AKIA...`)
- **Secret Access Key**

Use `AskUserQuestion` to confirm the user has both values saved before proceeding.

### If they already have an AWS account:

Use `AskUserQuestion` to confirm they have an IAM user with appropriate permissions and access keys ready before proceeding to Phase 3.

---

## Phase 3: AWS CLI Installation

Check if the AWS CLI is installed by running:

```bash
aws --version
```

### If the AWS CLI is installed:

Confirm the version and proceed to Phase 4.

### If the AWS CLI is NOT installed:

Use `AskUserQuestion` to ask if they want to install it. If yes, use `AskUserQuestion` to ask which OS they are on, then guide them through installing the AWS CLI using your knowledge of the official installation process for their platform, or research the official AWS documentation if needed.

After installation, verify with `aws --version`. If it fails, the user may need to open a new terminal or add it to their PATH.

---

## Phase 4: AWS CLI Profile Configuration

Use `AskUserQuestion` to collect the following values one at a time:

1. **Profile name** — the name for the AWS CLI named profile (default: `exasol`)
2. **AWS Access Key ID** — from their IAM user
3. **AWS Secret Access Key** — from their IAM user
4. **Default region** — AWS region to deploy in (e.g., `eu-west-1`, `us-east-1`, `eu-central-1`)
5. **Default output format** — `text`, `json`, or `table` (default: `text`)

Then use `AskUserQuestion` to ask: **"Would you like me to run the AWS CLI commands to set up the profile for you, or would you prefer to run them yourself?"**

**If they want you to run the commands**, execute:

```bash
aws configure set aws_access_key_id <ACCESS_KEY_ID> --profile <profile-name>
aws configure set aws_secret_access_key <SECRET_ACCESS_KEY> --profile <profile-name>
aws configure set region <REGION> --profile <profile-name>
aws configure set output <OUTPUT_FORMAT> --profile <profile-name>
```

**If they want to run the commands themselves**, show them the commands with their values filled in so they can copy and run them.

Ask them to confirm once done.

Either way, verify the configuration afterwards:

```bash
aws sts get-caller-identity --profile <profile-name>
```

This should return the account ID and IAM user ARN. If it fails, the credentials are incorrect — ask the user to double-check and retry.

---

## Phase 5: Exasol CLI Installation

Check if the `exasol` CLI is installed:

```bash
exasol version
```

### If not installed:

Install it by running:

```bash
curl https://downloads.exasol.com/exasol-personal/installer.sh | sh
```

After installation, verify with `exasol version`. If the command is not found, the user may need to open a new terminal or add `~/.exasol/bin` to their PATH.

---

## Phase 6: Deployment

Use `AskUserQuestion` to ask for:

1. **Deployment directory name** (default: `exasol-deployment`)
2. **Deployment directory location** (default: current working directory)

Then execute the following steps:

### Step 1: Export the AWS profile

```bash
export AWS_PROFILE=<profile-name>
```

Use the profile name from Phase 4.

### Step 2: Create and enter the deployment directory

```bash
mkdir -p <location>/<directory-name>
cd <location>/<directory-name>
```

### Step 3: Deploy Exasol

```bash
exasol install aws
```

Tell the user:
- This will take **10–20 minutes**.
- The CLI generates Terraform configs, provisions AWS infrastructure, and installs the Exasol database.
- Do not interrupt the process.

### Step 4: Verify deployment

After installation completes, run:

```bash
exasol info
```

This shows connection details including the host, port, and credentials. The credentials are also stored in `deployment.json` in the deployment directory.

Test the connection using `exasol connect` (the built-in SQL client):

```bash
exasol connect
```

Type `SELECT 1;` and press Enter. If it returns a result, the deployment is working. Type `exit` or press Ctrl+D to quit.

Tell the user:
- **All `exasol` commands must be run from the deployment directory.**
- `exasol stop` pauses the instance (but networking/storage costs continue).
- `exasol start` restarts a stopped instance (IP addresses change — use `exasol info` for new connection details).
- `exasol destroy` removes ALL AWS resources. **Never** delete the deployment directory without running `exasol destroy` first.

---

## Phase 7: Set Up exapump and Explore Data

Now help the user connect to their Exasol Personal database using `exapump` — the CLI tool used for SQL execution and data loading. The connection credentials are in `deployment.json` in the deployment directory.

### Step 1: Read the credentials

```bash
cat deployment.json
```

Note the host, port, username, and password — you will need these for the exapump profile.

### Step 2: Check if exapump is installed

```bash
exapump --version
```

If not installed, install it:

```bash
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh
```

Verify again after installation. If the command is not found, the user may need to open a new terminal or add `~/.exapump/bin` to their PATH.

### Step 3: Set up an exapump profile

List all existing profiles:

```bash
exapump profile list
```

**Never assume which profile to use.** Always ask the user explicitly:

- **If no profiles exist:** Use `AskUserQuestion` to ask: **"No exapump profiles found. Shall I create one? What would you like to name it?"** (suggest `exasol-personal`). Then create it:

  ```bash
  exapump profile add <name>
  ```

  This is interactive and will prompt for:
  - **Host** — from `deployment.json`
  - **Port** — from `deployment.json` (typically `8563`)
  - **Username** — from `deployment.json`
  - **Password** — from `deployment.json`
  - **TLS** — enter `y` (Exasol Personal uses a self-signed certificate; accept it)

- **If one or more profiles exist:** Use `AskUserQuestion` to ask: **"These profiles exist: [list]. Which would you like to use, or would you like to create a new one? Note: existing profiles may have stale credentials if the instance was restarted — would you like to update any of them with the current credentials from deployment.json?"**

  - **Use an existing profile as-is:** Note the profile name for use in subsequent commands.
  - **Update an existing profile:** Delete and recreate it:

    ```bash
    exapump profile remove <name>
    exapump profile add <name>
    ```

    Enter the credentials from `deployment.json` as above.

  - **Create a new profile:** Run `exapump profile add <name>` with the chosen name.

### Step 4: Test the connection

```bash
exapump sql --profile <chosen-profile> "SELECT 1"
```

If this fails, verify the credentials in `deployment.json` match what was entered. Offer to update the profile and retry.

### Step 5: Load sample data (Optional)

Use `AskUserQuestion` to ask: **"Would you like to load sample data? This includes a PRODUCTS table (1M rows, 27.3 MiB) and a PRODUCT_REVIEWS table (1.8M rows, 154.5 MiB)."**

If yes, use `exapump sql` to run the setup statements. Run these from the deployment directory:

**Step 5a:** Create the schema and tables, then import the data:

```bash
exapump sql --profile <chosen-profile> "CREATE SCHEMA IF NOT EXISTS SAMPLE_DATA"
exapump sql --profile <chosen-profile> "CREATE OR REPLACE TABLE SAMPLE_DATA.PRODUCTS (PRODUCT_ID DECIMAL(18,0), PRODUCT_CATEGORY VARCHAR(100), PRODUCT_NAME VARCHAR(2000000), PRICE_USD DOUBLE, INVENTORY_COUNT DECIMAL(10,0), MARGIN DOUBLE, DISTRIBUTE BY PRODUCT_ID)"
exapump sql --profile <chosen-profile> "IMPORT INTO SAMPLE_DATA.PRODUCTS FROM PARQUET AT 'https://exasol-easy-data-access.s3.eu-central-1.amazonaws.com/sample-data/' FILE 'online_products.parquet'"
exapump sql --profile <chosen-profile> "CREATE OR REPLACE TABLE SAMPLE_DATA.PRODUCT_REVIEWS (REVIEW_ID DECIMAL(18,0), PRODUCT_ID DECIMAL(18,0), PRODUCT_NAME VARCHAR(2000000), PRODUCT_CATEGORY VARCHAR(100), RATING DECIMAL(2,0), REVIEW_TEXT VARCHAR(100000), REVIEWER_NAME VARCHAR(200), REVIEWER_PERSONA VARCHAR(100), REVIEWER_AGE DECIMAL(3,0), REVIEWER_LOCATION VARCHAR(200), REVIEW_DATE VARCHAR(200), DISTRIBUTE BY PRODUCT_ID)"
exapump sql --profile <chosen-profile> "IMPORT INTO SAMPLE_DATA.PRODUCT_REVIEWS FROM PARQUET AT 'https://exasol-easy-data-access.s3.eu-central-1.amazonaws.com/sample-data/' FILE 'product_reviews.parquet'"
```

**Step 5b:** Verify row counts:

```bash
exapump sql --profile <chosen-profile> "SELECT COUNT(*) FROM SAMPLE_DATA.PRODUCTS"
exapump sql --profile <chosen-profile> "SELECT COUNT(*) FROM SAMPLE_DATA.PRODUCT_REVIEWS"
```

Expected results: PRODUCTS = 1,000,000 rows; PRODUCT_REVIEWS = 1,822,007 rows.

### Step 6: Explore the data

Tell the user that they can now use `/exasol` or ask naturally to query and explore their database. Suggest a few things they can do:

- **Run SQL queries:** Ask Claude to query the PRODUCTS or PRODUCT_REVIEWS tables — e.g. "show me the top 10 products by price" or "how many reviews per product category?"
- **Upload their own data:** Use `exapump upload` to load CSV or Parquet files into new tables
- **Export data:** Use `exapump export` to extract query results to local files
- **Explore schemas:** Ask Claude to list all tables and schemas in the database

The Exasol router activates the right database guidance automatically whenever the user asks for Exasol SQL, exapump, data loading, BucketFS, or UDF work. They can just describe what they want to do and Claude will guide them.
