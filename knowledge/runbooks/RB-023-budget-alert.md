# RB-023 - Budget threshold alert configuration

**Agent:** `finops`
**Match terms:** budget alert, threshold, notification, forecast

## Symptoms

Budget threshold alert configuration, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Retrieve the current budget configuration | `budget_get` | false |
| 2 | Apply the requested threshold | `budget_set` | true |

## Notes

Rollback: restore the previous threshold value, recorded before the change.
