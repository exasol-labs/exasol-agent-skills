# Exasol Personal Troubleshooting

Do not improvise fixes. Fetch the upstream documentation first — see
`references/upstream-docs.md` for the document list and raw URL pattern.

- **Local deployment misbehaving:** run `exasol diag local` for a JSON snapshot of VM status, guest IP, bound ports, and database readiness (README, **Start and stop Exasol Personal**).
- **Interrupted or failed cloud install:** rerun `exasol install <preset>` with the same presets to retry safely, or `exasol destroy` to clean up (README, **Deployments and Named Deployments**). An interrupted cloud install can leave billable resources behind, so do not simply abandon it.
- **Cached runtime artifacts:** `exasol cache list`, `exasol cache clean`, `exasol diag cache`.
- **Launcher not found after install:** the user may need a new terminal or a `PATH` adjustment as described by the installer output; confirm with `exasol version`.
- **Anything else:** re-read the relevant upstream section, or point the user at the [Exasol Community](https://community.exasol.com) using the `exasol-personal` tag.
