# RB-015 - Entra group membership request

**Agent:** `request-access`
**Match terms:** group, membership, entra, distribution, security group

## Symptoms

Entra group membership request, reported through the portal, email or a monitoring alert.

## Procedure

| # | Step | Tool | write |
|---|---|---|---|
| 1 | Confirm the requester's manager approved in the ticket | `entra_get_user` | false |
| 2 | Check current membership | `entra_get_user` | false |
| 3 | Add the user to the group | `entra_add_group_member` | true |

## Notes

Membership of privileged groups is out of scope for this runbook. Escalate those.
