# Script Language Container (SLC) Reference

## Prerequisites

- Python >= 3.10
- Docker >= 17.05 (multi-stage build support)
- 50 GB free disk for Docker images, 10 GB for build output

## Install exaslct

```bash
pip install exasol-script-languages-container-tool
```

## exaslct Commands

| Command | Description |
|---------|-------------|
| `exaslct build` | Build the container image |
| `exaslct export` | Build and export as `.tar.gz` archive |
| `exaslct deploy` | Build, export, and upload to BucketFS |
| `exaslct upload` | Upload a pre-built archive to BucketFS |
| `exaslct generate-language-activation` | Generate ALTER SESSION/SYSTEM SQL for activation |
| `exaslct security-scan` | Run security vulnerability scan on the container |
| `exaslct run-db-tests` | Run integration tests against an Exasol database |
| `exaslct clean` | Remove build artifacts and Docker images |

## Flavor Overview

### Standard Flavors (Pre-built, Full-featured)

| Flavor | Languages | Base Image |
|--------|-----------|------------|
| `standard-EXASOL-all` | Java 11, Python 3.10, R 4.4 | ubuntu:22.04 |
| `standard-EXASOL-all-java-11` | Java 11 | ubuntu:22.04 |
| `standard-EXASOL-all-java-17` | Java 17 | ubuntu:22.04 |
| `standard-EXASOL-all-python-3.10` | Python 3.10 | ubuntu:22.04 |
| `standard-EXASOL-all-python-3.12` | Python 3.12 | ubuntu:24.04 |
| `standard-EXASOL-all-r-4.4` | R 4.4 | ubuntu:22.04 |

### Template Flavors (Minimal, For Customization)

| Flavor | Pkg Mgr | GPU |
|--------|---------|-----|
| `template-Exasol-all-python-3.10` | pip | No |
| `template-Exasol-all-python-3.10-conda` | conda, pip | No |
| `template-Exasol-all-python-3.12` | pip | No |
| `template-Exasol-all-python-3.12-conda` | conda, pip | No |
| `template-Exasol-8-python-3.10-cuda-conda` | conda, pip | CUDA 12.9.1 |
| `template-Exasol-8-python-3.12-cuda-conda` | conda, pip | CUDA 12.9.1 |
| `template-Exasol-all-r-4` | CRAN | No |

### Flavor Selection Decision Tree

```
Need GPU/CUDA?
├─ YES → template-Exasol-8-python-3.{10,12}-cuda-conda
│        (Requires Exasol 2025.1+, NVIDIA driver on host)
└─ NO
   ├─ Need conda packages?
   │  ├─ YES → template-Exasol-all-python-3.{10,12}-conda
   │  └─ NO
   │     ├─ Need multiple languages (Java + Python + R)?
   │     │  ├─ YES → standard-EXASOL-all
   │     │  └─ NO
   │     │     ├─ Python → template-Exasol-all-python-3.{10,12}
   │     │     ├─ R → template-Exasol-all-r-4
   │     │     └─ Java → standard-EXASOL-all-java-{11,17}
```

### Python Version Guidance

- **3.10**: Broadest compatibility (all Exasol versions 7.1+)
- **3.12**: Newer packages, better performance; requires Exasol 8+ for some flavors

## Customization

### Directory Structure

```
flavors/<flavor-name>/flavor_customization/
├── Dockerfile              ← Custom RUN/COPY commands
└── packages/
    ├── python3_pip_packages  ← One package per line
    ├── apt_get_packages      ← System packages
    └── r_cran_packages       ← R packages
```

### Adding Python Packages (pip)

Edit `flavor_customization/packages/python3_pip_packages`:

```
# Format: package_name|version (version optional)
scikit-learn|1.3.2
pandas|2.1.4
numpy|1.26.2
```

### Adding System Packages (apt)

Edit `flavor_customization/packages/apt_get_packages`:

```
libgomp1
libopenblas-dev
curl
```

### Adding R Packages (CRAN)

Edit `flavor_customization/packages/r_cran_packages`:

```
dplyr|1.1.4
data.table
```

### Adding Conda Packages

Only available with `-conda` template flavors. Add to the Dockerfile:

```dockerfile
RUN conda install -y -c conda-forge \
    scikit-learn=1.3.2 \
    xgboost=2.0.3 && \
    conda clean -afy
```

### Custom Dockerfile Commands

Append to `flavor_customization/Dockerfile`:

```dockerfile
# Install from git
RUN pip install git+https://github.com/some/package.git@v1.0.0

# Install system libraries needed by Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev && \
    rm -rf /var/lib/apt/lists/*
```

**Rules:**
- No `FROM` commands allowed
- Only filesystem-changing commands take effect (`RUN`, `COPY`, `ADD`)
- `WORKDIR`, `USER`, `ENV` are NOT carried into the final container
- Prefix source paths with `flavor_customization/` for `COPY`/`ADD`

## Build + Deploy Workflow

### 1. Clone the Repository

```bash
git clone --recurse-submodules https://github.com/exasol/script-languages-release.git
cd script-languages-release
```

### 2. Customize Packages

Edit the appropriate package files in `flavors/<flavor>/flavor_customization/packages/`.

### 3. Build and Export

```bash
exaslct export --flavor-path=flavors/<flavor-name> --export-path ./output
```

### 4. Deploy to BucketFS

```bash
exaslct deploy --flavor-path=flavors/<flavor-name> \
    --bucketfs-host <hostname> --bucketfs-port <port> \
    --bucketfs-user w --bucketfs-password <password> \
    --bucketfs-name <bfs-name> --bucket <bucket-name> \
    --path-in-bucket <path> --bucketfs-use-https 1
```

### 5. Generate Activation SQL

```bash
exaslct generate-language-activation --flavor-path=flavors/<flavor-name> \
    --bucketfs-name <bfs-name> --bucket-name <bucket-name> \
    --path-in-bucket <path> --container-name <container-name>
```

### 6. Activate in Exasol

```sql
-- Current session only
ALTER SESSION SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///<bfs-name>/<bucket>/<path>/<container>?lang=python#buckets/<bfs-name>/<bucket>/<path>/<container>/exaudf/exaudfclient_py3';

-- System-wide (requires admin)
ALTER SYSTEM SET SCRIPT_LANGUAGES='...';
```

### 7. Verify

```sql
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT test_packages()
RETURNS VARCHAR(2000) AS
import sklearn, pandas, numpy
def run(ctx):
    return f"sklearn={sklearn.__version__}, pandas={pandas.__version__}, numpy={numpy.__version__}"
/

SELECT test_packages();
```

## Using Pre-built Containers

Skip building entirely — download from [GitHub releases](https://github.com/exasol/script-languages-release/releases):

1. Download the `.tar.gz` for the desired flavor
2. Upload to BucketFS (via HTTP PUT or BucketFS client)
3. Generate and execute activation SQL

## CUDA / GPU Notes

- Requires NVIDIA driver on the Exasol host OS (not included in the container)
- CUDA driver older than v575: also install `cuda-compat` 12.9.1
- Minimum Exasol version: 2025.1+
- Use `-cuda-conda` template flavors

## Troubleshooting

### Build Issues

**Insufficient disk space:**
```bash
docker system prune -a   # Remove unused images/containers
docker builder prune      # Clear build cache
```
Ensure 50 GB free on Docker image partition and 10 GB on build output directory.

**Docker permission denied:**
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

**Build takes very long — use registry caching:**
```bash
exaslct export --flavor-path=flavors/<flavor> --export-path ./output \
    --cache-registry <registry-url> --cache-tag <tag>
```

**macOS limitations:** All arguments (flavor paths, output directories) must be within the current directory due to Docker volume mount restrictions.

### Package Installation Failures

**pip package fails:** Common causes are missing system dependencies (add to `apt_get_packages`), Python version incompatibility, or needing a newer pip (add `pip` to `python3_pip_packages`).

**R package compilation fails:** Usually missing `-dev` system libraries:
```
libcurl4-openssl-dev
libxml2-dev
libssl-dev
```

### Upload / BucketFS Issues

- Verify BucketFS port is correct and reachable
- Use `--bucketfs-use-https 1` if TLS is enabled
- Verify write password is correct
- For large containers, use a template flavor to minimize size

### Activation Issues

**"Container not found":** Check that the archive is fully uploaded, path matches, and container name matches the archive name without `.tar.gz`.

**"Script language not found":** Verify the language alias in `SCRIPT_LANGUAGES` matches the UDF's language clause (e.g., `PYTHON3`, `JAVA`, `R`).

**"Module not found" after update:** Run `ALTER SESSION SET SCRIPT_LANGUAGES` again to pick up the new container. Check that the package was installed for the correct Python version.

### Testing

```bash
# Run integration tests against a container
exaslct run-db-test --flavor-path=flavors/<flavor>

# Test against specific Exasol version
exaslct run-db-test --flavor-path=flavors/<flavor> \
    --docker-db-image-version 7.1.10

# Test against external database
exaslct run-db-test --flavor-path=flavors/<flavor> \
    --environment-type external_db \
    --external-exasol-db-host <host> \
    --external-exasol-db-port <port> \
    --external-exasol-bucketfs-port <bfs-port> \
    --external-exasol-db-user <user> \
    --external-exasol-db-password <pass> \
    --external-exasol-bucketfs-write-password <bfs-pass>
```
