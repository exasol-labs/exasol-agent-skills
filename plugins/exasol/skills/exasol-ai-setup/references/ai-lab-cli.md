# notebook-connector `ai-lab` CLI

Use `ai-lab` when the user wants bundled notebooks or to launch JupyterLab.

## What `ai-lab` Does

- `ai-lab deploy-notebooks` copies the packaged notebooks into a target directory.
- `ai-lab start` launches JupyterLab and makes the bundled notebooks available under the notebook directory.
- `ai-lab` does not create the SCS file itself. Configure `scs` or `Secrets` first.

## Help

```bash
ai-lab --help
ai-lab deploy-notebooks --help
ai-lab start --help
```

## Typical Workflow

Copy the bundled notebooks without starting JupyterLab:

```bash
ai-lab deploy-notebooks --target-dir ~/work/notebooks
```

Start JupyterLab on the default port after configuration already exists:

```bash
ai-lab start --notebook-dir ~/work/notebooks
```

Expose JupyterLab remotely or use a custom port:

```bash
ai-lab start \
  --notebook-dir ~/work/notebooks \
  --port 9999 \
  --ip 0.0.0.0 \
  --no-browser
```

## Guidance

- Use `deploy-notebooks` when the user wants to inspect or edit notebooks before launch.
- Use `start` when the user explicitly wants a running JupyterLab server.
- If the user is missing config, switch back to `scs` or `Secrets` setup first.
