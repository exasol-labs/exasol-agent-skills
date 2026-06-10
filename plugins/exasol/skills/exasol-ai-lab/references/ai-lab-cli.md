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

`ai-lab start` launches `python -m jupyter lab`. Before JupyterLab starts,
Notebook Connector copies the bundled notebooks into the notebook root
directory, preserves existing files, and exports `NOTEBOOKS` for the launched
session.

```bash
ai-lab start
```

Common options:

- `--port` defaults to `49494`
- `--ip` defaults to `localhost`
- `--notebook-dir` uses the current working directory when omitted and creates missing directories
- `--no-browser` prevents opening the default browser

Useful variants:

```bash
ai-lab start --port 9999 --ip 0.0.0.0
ai-lab start --notebook-dir ~/work/notebooks --no-browser
```

Failure cases to keep in mind:

- if JupyterLab is not installed, the command exits with an install hint
- if `--notebook-dir` points to a file, the command exits with an error

## Deploy Notebooks Without Starting JupyterLab

Use `deploy-notebooks` when the user wants the bundled notebooks copied into a
target directory without starting JupyterLab.

```bash
ai-lab deploy-notebooks --target-dir ~/work/notebooks
ai-lab deploy-notebooks --target-dir ~/work/notebooks --overwrite
```

Behavior:

- `--target-dir` is required
- existing files are preserved unless `--overwrite` is used
- the command reports how many files were copied or skipped
