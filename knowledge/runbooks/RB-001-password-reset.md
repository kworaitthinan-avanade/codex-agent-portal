# RB-001 - Password reset and account lockout

**Agent:** `service-desk`
**Match terms:** password, lockout, cannot login, locked out, reset

## Symptoms

Password reset and account lockout, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Confirm the user identity via the registered caller field | `kb_search` | false |
| 2 | Check lockout status in the directory | `entra_get_user` | false |
| 3 | Reply with the self-service reset URL and the unlock window | `ticket_comment` | false |

## Notes

Self-service reset is always preferred. Never reset on the user's behalf from this runbook.
