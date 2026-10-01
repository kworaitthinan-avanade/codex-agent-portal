# RB-032 - Low disk space warning

**Agent:** `ops-automation`
**Match terms:** disk, storage, space, volume, full

## Symptoms

Low disk space warning, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Confirm the alarm and the affected volume | `cloudwatch_get_alarms` | false |
| 2 | Identify the largest consumers from the log agent | `log_query` | false |

## Notes

Report the finding. Deletion is never automated.
