# Upstream Documentation Is the Source of Truth

The scheduler ships its own normative documentation, including a reference
written specifically for agents. The bundled references in this skill cover the
stable SQL surface; for anything they do not settle — exact failure semantics,
configuration options, installation, hardening — fetch the upstream document
and follow it rather than answering from memory.

**The official repository:**

```
https://github.com/exasol-labs/exasol-scheduler
```

## Documents to Fetch

| Document | Fetch when |
|---|---|
| `docs/agent-skill.md` | The normative agent reference — pipeline design, exact execution and failure semantics, history-query patterns; fetch it before designing a non-trivial task graph |
| `docs/configuration.md` | Environment variables, DSN format, polling and connection options |
| `docs/security.md` | Trust model, least-privilege setup, credential management, hardening checklist |
| `docs/operations.md` | Building, systemd and Docker deployment, contract tests |
| `README.md` | Overview, quick start, task-definition walkthrough |

Raw URL pattern:

```
https://raw.githubusercontent.com/exasol-labs/exasol-scheduler/master/<document>
```

## When a Fetch Fails

If the host is unreachable or the document has moved, do not improvise the
missing content from memory. Tell the user which document could not be
retrieved and why, then offer to either retry or have them open it themselves
and paste the relevant section:

```
https://github.com/exasol-labs/exasol-scheduler/blob/master/<document>
```

The task-management SQL bundled with this skill (`task-management.md`) remains
safe to use offline — it is the scheduler's stable table surface. Anything
that installs, provisions, or hardens is not.
