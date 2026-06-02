# `ai-lab` CLI Reference

The `ai-lab` CLI exposes exactly two subcommands:

- `start`
- `deploy-notebooks`

## Help

Use these commands first when the user wants to inspect the exact `ai-lab` command surface before running anything.

```bash
ai-lab --help
ai-lab start --help
ai-lab deploy-notebooks --help
```

## Start JupyterLab

This is the minimal happy-path command when the user wants notebook-connector to prepare the notebook directory and launch JupyterLab immediately.

```bash
ai-lab start
```

Useful variants:

Use these variants when the user needs explicit control over the network binding, browser behavior, or notebook root directory.

```bash
ai-lab start --port 49494
ai-lab start --ip 0.0.0.0 --no-browser
ai-lab start --notebook-dir ~/work/notebooks
```

## Deploy Notebooks Without Starting JupyterLab

Use these commands when the user wants the bundled notebooks copied locally without starting a JupyterLab process.

```bash
ai-lab deploy-notebooks --target-dir ~/work/notebooks
ai-lab deploy-notebooks --target-dir ~/work/notebooks --overwrite
```

## Behavior

- `ai-lab start` launches `python -m jupyter lab`
- the bundled notebooks are copied into the notebook root directory first
- missing notebook directories are created
- if `--notebook-dir` points to a file, the command exits with an error
