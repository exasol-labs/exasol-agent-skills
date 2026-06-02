# `ai-lab` CLI Reference

The `ai-lab` CLI exposes exactly two subcommands:

- `start`
- `deploy-notebooks`

## Help

```bash
ai-lab --help
ai-lab start --help
ai-lab deploy-notebooks --help
```

## Start JupyterLab

```bash
ai-lab start
```

Useful variants:

```bash
ai-lab start --port 49494
ai-lab start --ip 0.0.0.0 --no-browser
ai-lab start --notebook-dir ~/work/notebooks
```

## Deploy Notebooks Without Starting JupyterLab

```bash
ai-lab deploy-notebooks --target-dir ~/work/notebooks
ai-lab deploy-notebooks --target-dir ~/work/notebooks --overwrite
```

## Behavior

- `ai-lab start` launches `python -m jupyter lab`
- the bundled notebooks are copied into the notebook root directory first
- missing notebook directories are created
- if `--notebook-dir` points to a file, the command exits with an error
