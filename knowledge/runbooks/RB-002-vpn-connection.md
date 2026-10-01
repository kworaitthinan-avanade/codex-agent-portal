# RB-002 - VPN client cannot connect

**Agent:** `service-desk`
**Match terms:** vpn, cannot connect, tunnel, remote access, disconnected

## Symptoms

VPN client cannot connect, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Confirm the client version against the supported baseline | `kb_search` | false |
| 2 | Check for a known outage notice | `kb_search` | false |
| 3 | Reply with the reinstall procedure and the status page link | `ticket_comment` | false |

## Notes

If a regional outage is active, do not troubleshoot the client. Link the notice and close.
