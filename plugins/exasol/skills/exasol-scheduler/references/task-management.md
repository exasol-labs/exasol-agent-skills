# Managing Scheduler Tasks

Tasks live in `SCHED_TASKS`; every execution writes a row to `SCHED_HISTORY`.
The default schema is `SCHED` — when the deployment sets `EXA_SCHEMA`, replace
`SCHED` in every statement below with that schema.

Always double-quote the scheduler's column names (`"TASK_ID"`, `"SQL_TEXT"`),
and write them with plain quotes — a backslash-escaped `\"TASK_ID\"` is only
valid inside an outer shell quoting layer and is an invalid token everywhere
else. `SQL_TEXT` replaces the legacy `STATEMENT` column name, which collided
with an Exasol reserved word.

## SCHED_TASKS columns

| Column | Meaning |
|---|---|
| `TASK_ID` | Unique identifier; children name their parent by it |
| `ENABLED` | `FALSE` pauses without deleting (default `TRUE`) |
| `SCHEDULE` | When a root fires; `NULL` for children and finalizers |
| `SQL_TEXT` | The SQL to execute — any valid Exasol SQL, including `EXECUTE SCRIPT` |
| `AFTER` | Parent's `TASK_ID`; `NULL` for roots |
| `IS_FINAL` | `TRUE` = finalizer: always runs after its parent, even on failure |
| `PARALLEL_CHILDREN` | `TRUE` (default) runs direct children in parallel; `FALSE` runs them sequentially in alphabetical `TASK_ID` order |
| `COMMENT` | Free text, ignored by the scheduler |

## Schedule syntax

Six cron fields — **seconds first** — plus an optional IANA timezone:

```
CRON <second> <minute> <hour> <day-of-month> <month> <day-of-week> [TZ=<zone>]
```

Without `TZ=`, the scheduler host's local timezone applies — state the timezone
you mean, because the host clock is not the schedule's clock. Day-of-week is
standard cron numbering (0=Sunday; names like `MON-FRI` also work).

| Schedule | Fires |
|---|---|
| `CRON 0 0 * * * * TZ=UTC` | every hour on the hour, UTC |
| `CRON 0 0 6 * * * TZ=Europe/Berlin` | daily at 06:00 Berlin time |
| `CRON 0 0 9 * * 1-5 TZ=America/New_York` | weekdays at 09:00 New York time |

## Defining tasks

A root task fires on its own schedule:

```sql
INSERT INTO SCHED.SCHED_TASKS ("TASK_ID", "SCHEDULE", "SQL_TEXT")
VALUES ('load_sales', 'CRON 0 0 6 * * * TZ=Europe/Berlin',
        'EXECUTE SCRIPT ETL.LOAD_SALES()');
```

A child runs when its parent succeeds — `AFTER` names the parent, `SCHEDULE`
is `NULL`:

```sql
INSERT INTO SCHED.SCHED_TASKS ("TASK_ID", "SCHEDULE", "SQL_TEXT", "AFTER")
VALUES ('transform', NULL, 'EXECUTE SCRIPT ETL.TRANSFORM()', 'load_sales');
```

A finalizer (`IS_FINAL = TRUE`) always runs after its parent — success or
failure — the place for notification and cleanup steps:

```sql
INSERT INTO SCHED.SCHED_TASKS ("TASK_ID", "SCHEDULE", "SQL_TEXT", "AFTER", "IS_FINAL")
VALUES ('notify', NULL, 'EXECUTE SCRIPT ETL.SEND_STATUS()', 'load_sales', TRUE);
```

The scheduler notices new and changed rows on its next poll — an `INSERT` is a
deploy, an `UPDATE` is a config change, and **no restart is ever needed**. Hot
reload is not atomic across separately committed statements, though: deploy a
multi-row task graph in one transaction with a single commit, or the scheduler
can load a half-built graph between commits.

## Managing tasks

```sql
-- Pause and resume
UPDATE SCHED.SCHED_TASKS SET "ENABLED" = FALSE WHERE "TASK_ID" = 'load_sales';
UPDATE SCHED.SCHED_TASKS SET "ENABLED" = TRUE  WHERE "TASK_ID" = 'load_sales';

-- Change schedule or SQL
UPDATE SCHED.SCHED_TASKS SET "SCHEDULE" = 'CRON 0 0 7 * * * TZ=UTC' WHERE "TASK_ID" = 'load_sales';

-- Remove
DELETE FROM SCHED.SCHED_TASKS WHERE "TASK_ID" = 'obsolete_job';
```

## Graph execution rules

- Every root trigger starts a **graph run**; all its history rows share one
  `GRAPH_RUN_ID` — the key for correlating a pipeline run.
- A failed or skipped parent skips all its children (recorded as `SKIPPED`);
  finalizers still run.
- A **root failure exits the scheduler process** after bookkeeping completes —
  every unrelated pipeline in that process stops until a supervisor restarts
  it. Child and finalizer failures are non-fatal. Pipeline families that need
  separate failure domains belong in separate scheduler processes with
  distinct task tables.
- Tasks whose `AFTER` forms a cycle or names a nonexistent `TASK_ID` are
  **silently excluded** — never run, never recorded. Fixing the reference
  reactivates them on the next reload.
- A disabled child or finalizer executes as `SKIPPED` with
  `ERROR_MESSAGE = 'task is disabled'`; a disabled root simply never fires.

## Auditing

```sql
-- Recent executions
SELECT "TASK_ID", "STATUS", "ERROR_MESSAGE", "STARTED_AT"
FROM SCHED.SCHED_HISTORY
ORDER BY "STARTED_AT" DESC LIMIT 20;

-- All steps of a pipeline's most recent run
SELECT "TASK_ID", "GRAPH_PHASE", "STATUS", "ERROR_MESSAGE", "STARTED_AT"
FROM SCHED.SCHED_HISTORY
WHERE "GRAPH_RUN_ID" = (
    SELECT "GRAPH_RUN_ID" FROM SCHED.SCHED_HISTORY
    WHERE "TASK_ID" = 'load_sales'
    ORDER BY "STARTED_AT" DESC LIMIT 1)
ORDER BY "STARTED_AT";
```

`STATUS` is `SUCCEEDED`, `FAILED`, or `SKIPPED`; a task row rejected while
loading is recorded as `INVALID` with `GRAPH_PHASE = 'VALIDATION'`. In
parallel mode sibling order is non-deterministic — reconstruct sequence from
`STARTED_AT`/`FINISHED_AT`, never from `TASK_ID` order.

`SCHED_HISTORY` records attempted runs, not scheduler uptime: a trigger missed
while the process was down leaves **no row at all** and is not replayed after
restart. History queries alone cannot distinguish downtime from a task that
was not due — that is what the scheduler's process logs are for.

There is no dry-run command. To verify a schedule fires when expected, insert
a test task, watch `SCHED_HISTORY` for its row, then delete it.
